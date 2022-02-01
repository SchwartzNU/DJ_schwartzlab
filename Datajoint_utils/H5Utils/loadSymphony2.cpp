#include "mex.hpp"
#include "mexAdapter.hpp"
#include "H5Cpp.h"
#include <unordered_set>
#include <unordered_map>
// #include <time.h>
#include <ctime>
#include <chrono>
#include <iomanip>
#include <sstream>
#include <numeric>

//H5::H5std_string <- for future reference

using namespace matlab::data;
using matlab::mex::ArgumentList;
//using matrix::detail::noninlined::mx_array_api::mxDeserialize; // seems this has been dropped


//stackoverflow ->
constexpr unsigned int str2int(const char* str, int h = 0) {
    return !str[h] ? 5381 : (str2int(str, h+1) * 33) ^ str[h];
}

struct pair {
    uint64_t first;
    std::string second;

    bool operator==(const pair &other) const {
        return (first == other.first && second == other.second);
    }
};
struct pair_hash {
    std::uint64_t operator() (const pair &p) const {
        return std::hash<uint64_t>()(p.first) ^ std::hash<std::string>()(p.second);
        //just xors the hash of the individual elements
    }
};
//end stackoverflow <-
typedef struct symphony_resource {
    std::string name;
    // buffer_ptr_t<char unsigned> ptr;
    hsize_t size;
} symphony_resource;

struct channel {
    uint64_t channel_ind;
    char units[10];
};

typedef struct note_time {
    long long ticks;
    double offset;
} note_time;

typedef struct note_data {
    note_time entry_time;
    char* text;
} note_data;

ArrayFactory factory;
class Parser {
    private:
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr;
        std::unordered_set<haddr_t> addrs;
        StructArray key = factory.createStructArray({1,1},
        {"experiment","calibration","epoch_groups","epoch_blocks","epochs",
        "channels","electrodes","epoch_channels",
        "sources","retinas","cells","cell_pairs",
        "experiment_notes","source_notes",
        "epoch_group_notes","epoch_block_notes","epoch_notes"}
        );
        // CharArray fname;
        std::string fname;
        std::string lastDevice;

        std::unordered_map<std::string, std::pair<symphony_resource,buffer_ptr_t<char unsigned>>> resources;
        std::unordered_map<std::string, uint64_t> sources;
        std::unordered_map<std::string, uint64_t> groups;
        std::unordered_map<std::string, uint64_t> blocks;
        std::unordered_map<std::string, uint64_t> epochs;
        std::unordered_map<std::string, uint64_t> responses;
        
        std::unordered_map<pair, channel, pair_hash> channels;
        
        long long experiment_date;

        H5::CompType data = H5::CompType(sizeof(double));//(sizeof(double));
        H5::CompType units = H5::CompType(10*sizeof(char));//(sizeof(std::string));
        char unit_i[10]; 

        H5::CompType note_type = H5::CompType(sizeof(note_data));
        H5::CompType time_type = H5::CompType(sizeof(note_time));
        
    public:
        Parser(std::string fpath, ArgumentList output, std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr): matlabPtr(matlabPtr) {
            data.insertMember("quantity", 0, H5::PredType::NATIVE_DOUBLE);
            units.insertMember("units", 0, H5::DataType(H5T_STRING, 10));
            
            time_type.insertMember("ticks", HOFFSET(note_time, ticks), H5::PredType::NATIVE_LLONG);

            note_type.insertMember("time", HOFFSET(note_data, entry_time), time_type);
            note_type.insertMember("text", HOFFSET(note_data, text), H5::StrType(0,H5T_VARIABLE));
            
            H5::H5File file = H5::H5File(fpath.c_str(), H5F_ACC_RDONLY);
            
            auto s = factory.createStructArray({1,1},
                {"experiment_start_time", "experiment_end_time",
                "file_name","rig_name",
                "symphony_major_version","symphony_minor_version",
                "symphony_patch_version","symphony_revision_version"});

            std::string version;
            auto attr = file.openAttribute("symphonyVersion");
            auto strtype = attr.getStrType();
            attr.read(strtype, version);
            attr.close();
            
            auto it0 = version.find(".");
            s[0]["symphony_major_version"] = factory.createScalar(std::stoi(version.substr(0, it0)));
            
            auto it1 = version.find(".", it0+1);
            s[0]["symphony_minor_version"] = factory.createScalar(std::stoi(version.substr(it0+1, it1)));
            
            it0 = version.find(".", it1+1);
            s[0]["symphony_patch_version"] = factory.createScalar(std::stoi(version.substr(it1+1, it0)));
            
            it1 = version.find(".", it0+1);
            s[0]["symphony_revision_version"] = factory.createScalar(std::stoi(version.substr(it0+1, it1)));
            
            auto start = fpath.find_last_of("/\\") + 1;
            auto end = fpath.find_last_of(".h5")-2;
            
            fname = fpath.substr(start, end - start);
            s[0]["file_name"] = factory.createCharArray(fname);
            s[0]["rig_name"] = factory.createCharArray(fpath.substr(end-1, 1));

            //TODO: get the branch and commit from newer files
            
            key[0]["experiment"] = std::move(s);    
            recurse(file);
            file.close();

            sortEpochs();
            mapResources();

            output[0] = std::move(key);
        }

        template <class T>
    void recurse(T parent, const char* parent_type = "") {
        try {
            for (auto i=0; i<parent.getNumObjs(); i++) {
                auto name = parent.getObjnameByIdx(i);
                
                if (parent.childObjType(name) == H5O_TYPE_DATASET) {
                } else if (parent.childObjType(name) == H5O_TYPE_GROUP) {
                    auto group = parent.openGroup(name);
                    H5O_info1_t info;
                    H5Oget_info2(group.getLocId(), &info, H5O_INFO_BASIC);
                    if (!addrs.count(info.addr)) {
                        addrs.insert(info.addr);
                        bool do_recurse = true;
                        auto group_type = name.substr(0,name.find("-")); //note the uuid...
                        switch (str2int(group_type.c_str())) {
                            //TODO: backgrounds, when we get those sorted for the projector...
                            //TODO: device resources, configuration settings...
                            case str2int("responses"):
                                parseResponses(group);
                                break;
                            case str2int("epoch"):
                                parseEpoch(group);
                                break;
                            case str2int("epochs"):
                                parseEpochs(group);
                                break;
                            case str2int("epochBlocks"):
                                parseEpochBlocks(group);
                                break;
                            case str2int("epochGroup"):
                                parseEpochGroup(group);
                                break;
                            case str2int("epochGroups"):
                                parseEpochGroups(group);
                                break;
                            case str2int("source"):
                                parseSource(group);
                                break;
                            case str2int("experiment"):
                                parseExperiment(group);
                                break;
                            default:
                                switch(str2int(parent_type)) {
                                    case str2int("responses"):
                                        parseResponse(group);
                                        break;
                                    case str2int("epochBlocks"):
                                        parseEpochBlock(group);
                                        break;
                                    case str2int("resources"):
                                        parseResource(group);
                                        break;
                                    case str2int("devices"):
                                        lastDevice = parseStrAttr(group, "name").toAscii();
                                        break;
                                    default:
                                        break;
                                }
                                break;
                        }
                        recurse(group, group_type.c_str());
                    }
                    group.close();
                }
            }
        } catch (H5::Exception e) {
            matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar(e.getDetailMsg())}));
        }
    }

    void parseExperiment(H5::Group experiment) {
        StructArray s = std::move(key[0]["experiment"]);
        if (!s[0]["experiment_start_time"].isEmpty()) throwError("multiple experiments!");
        
        parseDateTime(experiment, s[0]["experiment_start_time"], s[0]["experiment_end_time"]);        

        H5::Attribute attr;

        attr = experiment.openAttribute("startTimeDotNetDateTimeOffsetTicks");
        attr.read(H5::PredType::NATIVE_LLONG, &experiment_date);
        experiment_date = (experiment_date - 621357696000000000) / 10000; //milliseconds
        attr.close();

        key[0]["experiment"] = std::move(s);

        if (experiment.exists("notes")) {
            auto notes = experiment.openDataSet("notes");
            auto space = notes.getSpace();
            hsize_t n_samples;
            space.getSimpleExtentDims(&n_samples, NULL);

            StructArray s = factory.createStructArray({n_samples},
            {"file_name","entry_time", "text"});
            for (auto i=0; i<n_samples; i++) {
                s[i]["file_name"] = factory.createCharArray(fname);
            }
            s = parseNotes(notes, n_samples, std::move(s));
            key[0]["experiment_notes"] = matlabPtr->feval(u"vertcat", {std::move(key[0]["experiment_notes"]), std::move(s)});
            space.close();
            notes.close();
        }
    }

    void parseResource(H5::Group resource) {
        std::string resource_uuid = parseStrAttr(resource, "uuid").toAscii();
        std::string name = parseStrAttr(resource, "name").toAscii();
        if ((name == "descriptionType") | (name=="propertyDescriptors")) return;
        if (name == "configurationSettingDescriptors") name = lastDevice;
        if (resources.count(resource_uuid)) return;
        auto ds = resource.openDataSet("data");
        auto space = ds.getSpace();
        hsize_t n_samples;
        space.getSimpleExtentDims( &n_samples, NULL);
        
        buffer_ptr_t<char unsigned> buffer = factory.createBuffer<char unsigned>(n_samples);
        ds.read(buffer.get(), H5::PredType::NATIVE_UCHAR);
        
        // symphony_resource data = {parseStrAttr(resource, "name").toAscii(), n_samples};
        symphony_resource data;
        data.name = name;
        // data.ptr = std::move(buffer);
        data.size = n_samples;
        resources.insert({
            resource_uuid,
            std::pair<symphony_resource,buffer_ptr_t<char unsigned>>({
                data,
                std::move(buffer)
                })
            });

    }

    void mapResources() {
        auto n_elements = resources.size();
        CellArray cKeys = factory.createCellArray({n_elements, 1});
        CellArray cVals = factory.createCellArray({n_elements, 1});
        size_t i = 0;
        for (auto iter = resources.begin(); iter != resources.end(); iter++) {
            // c[i][0] = factory.createCharArray(iter->first); //uuid
            cKeys[i] = factory.createCharArray(iter->second.first.name); //name
            auto temp = factory.createArrayFromBuffer({iter->second.first.size},std::move(iter->second.second)); //buffer data
            cVals[i] = matlabPtr->feval(u"getArrayFromByteStream", {temp});
            i++;
        }

        key[0]["calibration"] = std::move(matlabPtr->feval(u"containers.Map", {cKeys, cVals}));
    }

    void parseEpochGroups(H5::Group epochGroups) {
        auto c_egs = epochGroups.getNumObjs();
        auto n_egs = c_egs;
        if (n_egs == 0) return; 

        for (auto i=0; i<c_egs; i++) {
            std::string name = epochGroups.getObjnameByIdx(i);
            auto epochGroup = epochGroups.openGroup(name);
            if (epochGroup.getNumObjs() == 0) {
                n_egs--;
            } else {
                auto group_uuid = parseStrAttr(epochGroup, "uuid").toAscii();
                if (groups.count(group_uuid)) {
                    n_egs--;
                } else {
                    auto ind = groups.size();
                    groups.insert({group_uuid, ind});
                }
            }
            epochGroup.close();
        }
        
        StructArray s = factory.createStructArray({n_egs}, {
            "epoch_group_id","source_id","epoch_group_start_time","epoch_group_end_time",
            "epoch_group_label","file_name"
        });

        for (auto i=0; i<n_egs; i++) {
            s[i]["file_name"] = factory.createCharArray(fname);
        }

        StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["epoch_groups"]), std::move(s)});
        key[0]["epoch_groups"] = std::move(result);
    }

    void parseEpochGroup(H5::Group epochGroup) {
        if (epochGroup.getNumObjs() == 0) return;

        auto group_uuid = parseStrAttr(epochGroup, "uuid").toAscii(); 
        // if (groups.count(group_uuid)) return;
        // auto ind = groups.size();
        // groups.insert({group_uuid, ind});
        auto ind = groups[group_uuid];

        StructArray s = std::move(key[0]["epoch_groups"]);
        
        
        s[ind]["epoch_group_id"] = factory.createScalar(ind + 1);
        parseDateTime(epochGroup, s[ind]["epoch_group_start_time"], s[ind]["epoch_group_end_time"]);
        

        s[ind]["epoch_group_label"] = parseStrAttr(epochGroup, "label");
        
       
        auto source = epochGroup.openGroup("source");
        auto s_id = factory.createScalar(parseSource(source));
        s[ind]["source_id"] = s_id;//factory.createScalar(s_id);
        source.close();

        key[0]["epoch_groups"] = std::move(s);

        if (epochGroup.exists("notes")) {

            auto notes = epochGroup.openDataSet("notes");
            auto space = notes.getSpace();
            hsize_t n_samples;
            space.getSimpleExtentDims(&n_samples, NULL);


            StructArray s = factory.createStructArray({n_samples},
            {"file_name", "source_id","epoch_group_id",
            "entry_time", "text"});
            for (auto i=0; i<n_samples; i++) {
                s[i]["file_name"] = factory.createCharArray(fname);
                s[i]["source_id"] = s_id;
                s[i]["epoch_group_id"] = factory.createScalar(ind + 1);
            }
            s = parseNotes(notes, n_samples, std::move(s));
            
            key[0]["epoch_group_notes"] = matlabPtr->feval(u"vertcat", {std::move(key[0]["epoch_group_notes"]), std::move(s)});
            
            space.close();
            notes.close();
        }
    }

    void parseEpochBlocks(H5::Group epochBlocks) {
        auto n_ebs = epochBlocks.getNumObjs();
        if (n_ebs == 0) return; 
        
        StructArray s = factory.createStructArray({n_ebs}, {
            "epoch_block_id","epoch_group_id","source_id",
            "epoch_block_start_time","epoch_block_end_time",
            "protocol_name","file_name",
            "parameters"
        });

        for (auto i=0; i<n_ebs; i++) {
            s[i]["file_name"] = factory.createCharArray(fname);
        }

        StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["epoch_blocks"]), std::move(s)});
        key[0]["epoch_blocks"] = std::move(result);

    }

    void parseEpochBlock(H5::Group epochBlock) {
        // auto group_uuid = parseStrAttr(epochGroup, "uuid");

        auto block_uuid = parseStrAttr(epochBlock, "uuid").toAscii(); 
        if (blocks.count(block_uuid)) return;
        auto ind = blocks.size();
        blocks.insert({block_uuid, ind});

        auto group = epochBlock.openGroup("epochGroup");
        auto group_ind = groups[parseStrAttr(group, "uuid").toAscii()];
        group.close();

        StructArray s = std::move(key[0]["epoch_blocks"]);

        s[ind]["epoch_block_id"] = factory.createScalar(ind + 1);
        s[ind]["epoch_group_id"] = factory.createScalar(group_ind + 1);
        parseDateTime(epochBlock, s[ind]["epoch_block_start_time"], s[ind]["epoch_block_end_time"]);
        

        StructArray group_s = key[0]["epoch_groups"];
        TypedArray<uint64_t> s_id = group_s[group_ind]["source_id"];
        s[ind]["source_id"] = s_id;

        s[ind]["protocol_name"] = parseProtocolName(epochBlock);
        
        auto params = epochBlock.openGroup("protocolParameters");
        s[ind]["parameters"] = parseParams(params);
        params.close();

        key[0]["epoch_blocks"] = std::move(s); 


        if (epochBlock.exists("notes")) {
            auto notes = epochBlock.openDataSet("notes");
            auto space = notes.getSpace();
            hsize_t n_samples;
            space.getSimpleExtentDims(&n_samples, NULL);

            StructArray s = factory.createStructArray({n_samples},
            {"file_name", "source_id",
            "epoch_group_id","epoch_block_id",
            "entry_time", "text"});
            for (auto i=0; i<n_samples; i++) {
                s[i]["file_name"] = factory.createCharArray(fname);
                s[i]["source_id"] = s_id;
                s[i]["epoch_block_id"] = factory.createScalar(ind);
                s[i]["epoch_group_id"] = factory.createScalar(group_ind + 1);
            }
            s = parseNotes(notes, n_samples, std::move(s));
            key[0]["epoch_block_notes"] = matlabPtr->feval(u"vertcat", {std::move(key[0]["epoch_block_notes"]), std::move(s)});
            space.close();
            notes.close();
        }
    }

    void parseEpochs(H5::Group epochs) {
        auto n_es = epochs.getNumObjs();
        if (n_es == 0) return; 
        
        StructArray s = factory.createStructArray({n_es}, {
            "epoch_id","epoch_block_id","epoch_group_id","source_id",
            "epoch_start_time","epoch_duration","file_name",
            "parameters"
        });

        for (auto i=0; i<n_es; i++) {
            s[i]["file_name"] = factory.createCharArray(fname);
        }

        StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["epochs"]), std::move(s)});
        key[0]["epochs"] = std::move(result);
    }

    void parseEpoch(H5::Group epoch) {
        // auto group_uuid = parseStrAttr(epochGroup, "uuid");
        auto epoch_uuid = parseStrAttr(epoch, "uuid").toAscii(); 
        if (epochs.count(epoch_uuid)) return;
        auto ind = epochs.size();
        epochs.insert({epoch_uuid, ind});

        auto block = epoch.openGroup("epochBlock");
        auto block_ind = blocks[parseStrAttr(block, "uuid").toAscii()];
        block.close();

        StructArray s = std::move(key[0]["epochs"]);

        s[ind]["epoch_id"] = factory.createScalar(ind + 1);
        s[ind]["epoch_block_id"] = factory.createScalar(block_ind + 1);
        
        parseEpochMilliseconds(epoch, s[ind]["epoch_start_time"], s[ind]["epoch_duration"]);
        
        StructArray block_s = key[0]["epoch_blocks"];
        TypedArray<uint64_t> s_id = block_s[block_ind]["source_id"];
        s[ind]["source_id"] = s_id;
        
        TypedArray<uint64_t> g_id = block_s[block_ind]["epoch_group_id"];
        s[ind]["epoch_group_id"] = g_id;

        
        auto params = epoch.openGroup("protocolParameters");
        
        s[ind]["parameters"] = parseParams(params);
        
        StructArray experiment = std::move(key[0]["experiment"]);
        // if (params.attrExists("micronsPerPixel")) {
        //     TypedArray<double> mpp = parseNumericAttr(params, "micronsPerPixel");
        //     TypedArray<double> mpp_e = experiment[0]["microns_per_pixel"];
        //     if (mpp_e.isEmpty()) {
        //         experiment[0]["microns_per_pixel"] = mpp;
        //     } else if (mpp_e[0] != mpp[0]) throwError("File has differing microns per pixel values!");
        // }
        // if (params.attrExists("angleOffsetFromRig")) {
        //     TypedArray<double> ao = parseNumericAttr(params, "angleOffsetFromRig");
        //     TypedArray<double> ao_e = experiment[0]["angle_offset"];
        //     if (ao_e.isEmpty()) {
        //         experiment[0]["angle_offset"] = ao;
        //     } else if (ao_e[0] != ao[0]) throwError("File has differing angle offset values!");
        // }
        key[0]["experiment"] = std::move(experiment);

        params.close();
        
        
        key[0]["epochs"] = std::move(s);

        if (epoch.exists("notes")) {
            auto notes = epoch.openDataSet("notes");
            auto space = notes.getSpace();
            hsize_t n_samples;
            space.getSimpleExtentDims(&n_samples, NULL);

            StructArray s = factory.createStructArray({n_samples},
            {"file_name", "source_id",
            "epoch_group_id","epoch_block_id","epoch_id",
            "entry_time", "text"});
            for (auto i=0; i<n_samples; i++) {
                s[i]["file_name"] = factory.createCharArray(fname);
                s[i]["source_id"] = s_id;
                s[i]["epoch_id"] = factory.createScalar(ind + 1);
                s[i]["epoch_block_id"] = factory.createScalar(block_ind + 1);
                s[i]["epoch_group_id"] = g_id;
            }
            s = parseNotes(notes, n_samples, std::move(s));
            key[0]["epoch_notes"] = matlabPtr->feval(u"vertcat", {std::move(key[0]["epoch_notes"]), std::move(s)});
            space.close();
            notes.close();
        }
    }

    void parseResponses(H5::Group responses) {
    }

    void parseResponse(H5::Group response) {
        auto response_uuid = parseStrAttr(response, "uuid").toAscii(); 
        
        if (responses.count(response_uuid)) return;
        auto ind = responses.size();
        responses.insert({response_uuid, ind});

        //read the data
        auto ds = response.openDataSet("data");
        auto space = ds.getSpace();
        hsize_t n_samples;
        space.getSimpleExtentDims( &n_samples, NULL);
        auto buffer = factory.createBuffer<double>(n_samples);
        ds.read(buffer.get(), data);

        // check the units <- 
        hsize_t offset = 0;
        space.selectElements(H5S_SELECT_SET, 1, &offset);
        ds.read(unit_i, units, H5::DataSpace::ALL, space);

        
        auto epoch = response.openGroup("epoch");
        auto epoch_id = epochs[parseStrAttr(epoch, "uuid").toAscii()]; 
        auto epochBlock = epoch.openGroup("epochBlock");
        auto epochs = epochBlock.openGroup("epochs");
        auto n_es = epochs.getNumObjs();
        epoch.close();
        epochs.close();

        StructArray epoch_s = std::move(key[0]["epochs"]);
        TypedArray<uint64_t> block_id = epoch_s[epoch_id]["epoch_block_id"];
        TypedArray<uint64_t> group_id = epoch_s[epoch_id]["epoch_group_id"];
        TypedArray<uint64_t> source_id = epoch_s[epoch_id]["source_id"];
        
        
        auto device = response.openGroup("device");
        auto name = parseStrAttr(device, "name").toAscii();
        
        TypedArray<double> sample_rate = parseNumericAttr(response, "sampleRate");
        if (parseStrAttr(response,"sampleRateUnits").toAscii() != "Hz") throwError("Bad units!");
        
        channel channel_i; 
        pair p = {block_id[0], name};
        if (channels.count(p)) {
            channel_i = channels[p];
        } else {
            //create new...
            channel_i.channel_ind = channels.size();
            std::memcpy(channel_i.units, unit_i, sizeof(unit_i));
            channels.insert({p, channel_i});
            StructArray channel_s = factory.createStructArray({1},{
                "file_name","source_id","epoch_group_id","epoch_block_id",
                "channel_name", "sample_rate"
            });
            
            channel_s[0]["file_name"] = factory.createCharArray(fname);
            channel_s[0]["source_id"] = source_id;
            channel_s[0]["epoch_group_id"] = group_id;
            channel_s[0]["epoch_block_id"] = block_id;
            channel_s[0]["channel_name"] = factory.createCharArray(name);
            channel_s[0]["sample_rate"] = sample_rate;

            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["channels"]), std::move(channel_s)});
            key[0]["channels"] = std::move(result);
            
            //also insert as many epoch_channels as there are epochs in this block
            StructArray s = factory.createStructArray({n_es}, {
                "file_name","source_id","epoch_group_id",
                "epoch_block_id","epoch_id","channel_name","raw_data"
            });
            result = matlabPtr->feval(u"vertcat",{std::move(key[0]["epoch_channels"]), std::move(s)});
            key[0]["epoch_channels"] = std::move(result);

            if (parseStrAttr(device, "manufacturer").toAscii() == "Molecular Devices") {
                //add the electrode
                StructArray electrode_s = factory.createStructArray({1}, {
                    "file_name","source_id","epoch_group_id","epoch_block_id",
                    "channel_name","amp_mode","recording_mode","hold","cell_id"
                });
                electrode_s[0]["file_name"] = factory.createCharArray(fname);
                electrode_s[0]["source_id"] = source_id;
                electrode_s[0]["epoch_group_id"] = group_id;
                electrode_s[0]["epoch_block_id"] = block_id;
                electrode_s[0]["channel_name"] = factory.createCharArray(name);

                int electrode_number;
                sscanf(name.c_str(),"%*[^0-9]%i", &electrode_number);
                
                auto protocol_params = epochBlock.openGroup("protocolParameters");

                char chan_mode[10], chan_hold[10];
                sprintf(chan_mode,"chan%dMode", electrode_number);
                sprintf(chan_hold,"chan%dHold", electrode_number);
                
                electrode_s[0]["amp_mode"] = parseStrAttr(protocol_params, chan_mode); //need to parse the channel name...
                if (std::strcmp(unit_i, "pA")) {
                    electrode_s[0]["recording_mode"] = factory.createCharArray("Voltage Clamp");
                } else if (std::strcmp(unit_i, "mV")) {
                    electrode_s[0]["recording_mode"] = factory.createCharArray("Current Clamp");
                } else throwError("Unknown eletrode unit type!");
                electrode_s[0]["hold"] = parseNumericAttr(protocol_params, chan_hold); //need to parse the channel name...
                
                auto epochGroup = epochBlock.openGroup("epochGroup");
                auto source = epochGroup.openGroup("source");
                auto props = source.openGroup("properties");

                if (props.attrExists("type")) {
                    //case cell
                    electrode_s[0]["cell_id"] = source_id;
                } else if (props.attrExists("Amplifier 1 cell number")) {
                    //case cell pair -- we need the corresponding cell...
                    char index[10];
                    sprintf(index,"cell_%d_id", electrode_number);
                    StructArray pairs = std::move(key[0]["cell_pairs"]);
                    for (auto elem : pairs) {
                        // TypedArray<uint64_t> cell_i = elem["source_id"];
                        matlab::data::Array temp = elem["source_id"];
                        TypedArray<uint64_t> cell_i = temp;
                        if (cell_i[0] == source_id[0]) {
                            auto s_id = elem[index];
                            electrode_s[0]["cell_id"] = factory.createScalar<uint64_t>(s_id[0]);
                        }
                    }
                    key[0]["cell_pairs"] = std::move(pairs);
                    
                } else if (props.attrExists("Description")){
                    //"other" source, do nothing
                } else if (props.attrExists("orientation")) {
                    //"retina" source, do nothing
                } else throwError("Unknown source type!");

                result = matlabPtr->feval(u"vertcat",{std::move(key[0]["electrodes"]), std::move(electrode_s)});
                key[0]["electrodes"] = std::move(result);

                props.close();
                source.close();
                epochGroup.close();
                protocol_params.close();

            }
                      
        }
        device.close();
        space.close();
        ds.close();
        epochBlock.close();
        

        StructArray channel_s = std::move(key[0]["channels"]);
        TypedArray<double> channel_sr = channel_s[channel_i.channel_ind]["sample_rate"];
        if (channel_sr[0] != sample_rate[0]) throwError("Unequal sample rates!");
        if (std::strcmp(unit_i, channel_i.units)) throwError("Channel units do not match!");

        
        key[0]["epochs"] = std::move(epoch_s);
        key[0]["channels"] = std::move(channel_s);

        StructArray s = std::move(key[0]["epoch_channels"]);
        s[ind]["file_name"] = factory.createCharArray(fname);
        s[ind]["source_id"] = source_id;
        s[ind]["epoch_group_id"] = group_id;
        s[ind]["epoch_block_id"] = block_id;
        s[ind]["epoch_id"] = factory.createScalar(epoch_id + 1);
        s[ind]["channel_name"] = factory.createCharArray(name);  
        s[ind]["raw_data"] = factory.createArrayFromBuffer<double>({1,n_samples}, std::move(buffer));

        key[0]["epoch_channels"] = std::move(s);
      
    }
    
    uint64_t parseSource(H5::Group source) {
        auto source_uuid = parseStrAttr(source, "uuid").toAscii();

        if (sources.count(source_uuid)) {
            return sources[source_uuid];
        }
        
        bool has_parent = source.exists("parent");
        uint64_t parent_ind;
        if (has_parent) {
            auto parent = source.openGroup("parent");
            parent_ind = parseSource(parent);
            parent.close();
        }
        auto ind = sources.size() + 1; //the parent ind should proceed this one
        sources.insert({source_uuid, ind});

        StructArray s = factory.createStructArray({1}, {
            "source_id","file_name","source_label"
        });
        s[0]["source_label"] = parseStrAttr(source, "label");
        s[0]["source_id"] = factory.createScalar(ind);
        s[0]["file_name"] = factory.createCharArray(fname);
 
        StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["sources"]), std::move(s)});
        key[0]["sources"] = std::move(result);

        auto props = source.openGroup("properties");
        if (props.attrExists("DataJoint Identifier")) {
            //case new-style retina
            s = factory.createStructArray({1},
            {"source_id","animal_id", "side", "orientation", "experimenter", "file_name"});
            s[0]["animal_id"] = parseStr2IntAttr(props, "DataJoint Identifier");
            s[0]["side"] = parseStrAttr(props, "eye");
            s[0]["orientation"] = parseStrAttr(props, "orientation");
            s[0]["experimenter"] = parseStrAttr(props, "recordingBy");
            s[0]["source_id"] = factory.createScalar(ind);
            s[0]["file_name"] = factory.createCharArray(fname);
            
            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["retinas"]), std::move(s)});
            key[0]["retinas"] = std::move(result);
        } else if (props.attrExists("genotype")) {
            //case old-style retina
            s = factory.createStructArray({1},
            {"source_id","animal_id", "side", "orientation", "experimenter", "file_name"});
            s[0]["animal_id"] = parseStrAttr(props, "genotype");
            s[0]["side"] = parseStrAttr(props, "eye");
            s[0]["orientation"] = parseStrAttr(props, "orientation");

            if (props.attrExists("recordingBy")) {
                s[0]["experimenter"] = parseStrAttr(props, "recordingBy");
            }
            s[0]["source_id"] = factory.createScalar(ind);
            s[0]["file_name"] = factory.createCharArray(fname);
            
            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["retinas"]), std::move(s)});
            key[0]["retinas"] = std::move(result);
        } else if (props.attrExists("type")) {
            //case cell
            s = factory.createStructArray({1},
            {"file_name","source_id","retina_id","cell_number",
            "online_type", "x", "y"});
            s[0]["online_type"] = parseStrAttr(props, "confirmedType");
            if (s[0]["online_type"].isEmpty()) s[0]["online_type"] = parseStrAttr(props, "type");

            parseLocAttr(props, s[0]["x"], s[0]["y"]);
            s[0]["cell_number"] = parseNumericAttr(props,"number");
            s[0]["retina_id"] = factory.createScalar(parent_ind);
            s[0]["source_id"] = factory.createScalar(ind);
            s[0]["file_name"] = factory.createCharArray(fname);
            
            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["cells"]), std::move(s)});
            key[0]["cells"] = std::move(result);

        } else if (props.attrExists("Amplifier 1 cell number")) {
            //case cell pair
            s = factory.createStructArray({1},
            {"file_name","source_id","cell_1_id","cell_2_id"});
            s[0]["source_id"] = factory.createScalar(ind);
            s[0]["file_name"] = factory.createCharArray(fname);
            
            //we want the cells with the matching number, not source_id...
            TypedArray<double> cell_1 = parseStr2DoubleAttr(props, "Amplifier 1 cell number");
            TypedArray<double> cell_2 = parseStr2DoubleAttr(props, "Amplifier 2 cell number");
            
            StructArray cells = std::move(key[0]["cells"]);

            for (auto& elem : cells) {
                TypedArray<double> cell_i = elem["cell_number"];
                if (cell_i[0] == cell_1[0]) {
                    auto s_id = elem["source_id"];
                    s[0]["cell_1_id"] = factory.createScalar<uint64_t>(s_id[0]);
                }
                if (cell_i[0] == cell_2[0]) {
                    auto s_id = elem["source_id"];
                    s[0]["cell_2_id"] = factory.createScalar<uint64_t>(s_id[0]);
                }
            }
            key[0]["cells"] = std::move(cells);

            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["cell_pairs"]), std::move(s)});
            key[0]["cell_pairs"] = std::move(result);

        } else if (props.attrExists("Description")){
            //TODO: add a note with the description of this cell!
        } else {
            //unparsed
            CharArray result = matlabPtr->feval(u"strcat",{factory.createCharArray("Unparseable source: "), parseStrAttr(source,"label")});
            matlabPtr->feval(u"error", 0, std::vector<Array>({result}));
        }
        if (source.exists("notes")) {
            auto notes = source.openDataSet("notes");
            auto space = notes.getSpace();
            hsize_t n_samples;
            space.getSimpleExtentDims(&n_samples, NULL);

            StructArray s = factory.createStructArray({n_samples}, {"file_name", "source_id", "entry_time", "text"});
            for (auto i=0; i<n_samples; i++) {
                s[i]["file_name"] = factory.createCharArray(fname);
                s[i]["source_id"] = factory.createScalar(ind);
            }
            s = parseNotes(notes, n_samples, std::move(s));
            key[0]["source_notes"] = matlabPtr->feval(u"vertcat", {std::move(key[0]["source_notes"]), std::move(s)});
            space.close();
            notes.close();
        }

        return ind;
    }

    StructArray parseParams(H5::Group parameters) {
        size_t n_attr = parameters.getNumAttrs();
        CellArray fieldNames = factory.createCellArray({n_attr});
        CellArray values = factory.createCellArray({n_attr});

        for (auto i=0; i<n_attr; i++) {
            auto attr = parameters.openAttribute(i);
            fieldNames[i] = factory.createCharArray(attr.getName());
            auto h5type = attr.getTypeClass();
            if ((h5type == H5T_INTEGER) | (h5type == H5T_FLOAT)) {
                size_t size = attr.getInMemDataSize() / sizeof(double);
                if (size > 1) {
                    auto data = factory.createBuffer<double>(size);
                    attr.read(attr.getDataType(), data.get());
                    values[i] = factory.createArrayFromBuffer<double>({1,size}, std::move(data));
                } else {
                    double data;
                    attr.read(H5::PredType::NATIVE_DOUBLE, &data);
                    values[i] = factory.createScalar(data);
                }
            } else if (h5type == H5T_STRING) {
                std::string data;
                // attr.read(H5::PredType::C_S1, data);
                auto strtype = attr.getStrType();
                attr.read(strtype, data);
                values[i] = factory.createCharArray(data);
            } else throwError("Unrecognized attribute type!");
            attr.close();
        }
        
        StructArray s = matlabPtr->feval(u"cell2struct", {std::move(values), std::move(fieldNames)});
        
        return std::move(s);
    }

    CharArray parseStrAttr(H5::Group group, std::string attr_name) {
        //can this be a template?
        auto attr = group.openAttribute(attr_name);
        auto strtype = attr.getStrType();
        std::string attr_value;

        attr.read(strtype, attr_value);
        // strtype.close();
        
        attr.close();
        return factory.createCharArray(attr_value);
    }

    Array parseStr2IntAttr(H5::Group group, std::string attr_name) {
        //can this be a template?
        auto attr = group.openAttribute(attr_name);
        auto strtype = attr.getStrType();
        std::string attr_value;

        attr.read(strtype, attr_value);
        // strtype.close();
        attr.close();
        return factory.createScalar(std::stoi(attr_value));
    }

    Array parseStr2DoubleAttr(H5::Group group, std::string attr_name) {
        //can this be a template?
        auto attr = group.openAttribute(attr_name);
        auto strtype = attr.getStrType();
        std::string attr_value;

        attr.read(strtype, attr_value);
        // strtype.close();
        attr.close();
        return factory.createScalar<double>(std::atof(attr_value.c_str()));
    }

    Array parseNumericAttr(H5::Group group, std::string attr_name) {
        auto attr = group.openAttribute(attr_name);
        double result;
        attr.read(H5::PredType::NATIVE_DOUBLE, &result);
        return factory.createScalar(result);
    }

    void parseLocAttr(H5::Group group, Reference<Array> x, Reference<Array> y) {
        auto attr = group.openAttribute("location");
        double xy[2];

        attr.read(H5::PredType::NATIVE_DOUBLE, &xy[0]);
        x = factory.createScalar(xy[0]);
        y = factory.createScalar(xy[1]);
    }

    CharArray parseProtocolName(H5::Group group) {
        //can this be a template?
        auto attr = group.openAttribute("protocolID");
        auto strtype = attr.getStrType();
        std::string attr_value;

        attr.read(strtype, attr_value);
        attr.close();
        return factory.createCharArray(attr_value.substr(attr_value.find_last_of(".")+1));
    }

    void parseDateTime(H5::Group group, Reference<Array> start, Reference<Array> end) {
        //shared timestamp code

        H5::Attribute attr;
        // H5::IntType inttype(H5T_STD_I64LE);
        long long ticks;

        attr = group.openAttribute("startTimeDotNetDateTimeOffsetTicks");
        attr.read(H5::PredType::NATIVE_LLONG, &ticks);
        parseDateTime(ticks, start);
        
        attr = group.openAttribute("endTimeDotNetDateTimeOffsetTicks");
        attr.read(H5::PredType::NATIVE_LLONG, &ticks);
        parseDateTime(ticks, end);
        
        attr.close();
    }

    void parseDateTime(long long ticks, Reference<Array> time_str) {
        //shared timestamp code
        std::stringstream buffer;
        ticks = (ticks - 621357696000000000) / 10000000;
        buffer << std::put_time(std::gmtime(&ticks), "%Y-%m-%d %H:%M:%S");
        time_str = factory.createCharArray(buffer.str());
    }

    StructArray parseNotes(H5::DataSet notes, hsize_t n_samples, StructArray note_field) {
        note_data* note = new note_data[n_samples];

        notes.read(note, note_type);//, H5::DataSpace::ALL, space);
        
        for (auto i=0; i<n_samples; i++) {
            parseDateTime(note[i].entry_time.ticks, note_field[i]["entry_time"]);
            note_field[i]["text"] = factory.createCharArray(note[i].text);
        }

        delete[] note;
        return std::move(note_field);
    }

    void parseEpochMilliseconds(H5::Group epoch, Reference<Array> start, Reference<Array> duration) {
        H5::Attribute attr;
        // H5::IntType inttype(H5T_STD_I64LE);
        long long ticks1, ticks2;

        attr = epoch.openAttribute("startTimeDotNetDateTimeOffsetTicks");
        attr.read(H5::PredType::NATIVE_LLONG, &ticks1);
        ticks1 = (ticks1 - 621357696000000000) / 10000; //milliseconds

        start = factory.createScalar(ticks1 - experiment_date);

        
        attr = epoch.openAttribute("endTimeDotNetDateTimeOffsetTicks");
        attr.read(H5::PredType::NATIVE_LLONG, &ticks2);
        ticks2 = (ticks2 - 621357696000000000) / 10000; //milliseconds

        duration = factory.createScalar(ticks2 - ticks1);

    }

    void sortEpochs() {
        //get the sort order for the epochs
        auto epoch_i = getOrder<long long>("epochs", "epoch_start_time");
        reorder("epochs", "epoch_id", epoch_i);
        reorder("epoch_channels", "epoch_id", epoch_i);
        reorder("epoch_notes", "epoch_id", epoch_i);

        //then do the same for epoch blocks and epoch groups
        auto eb_i = getOrder<char16_t>("epoch_blocks", "epoch_block_start_time");
        reorder("epochs","epoch_block_id", eb_i);
        reorder("epoch_blocks","epoch_block_id", eb_i);
        reorder("channels","epoch_block_id", eb_i);
        reorder("electrodes","epoch_block_id", eb_i);
        reorder("epoch_channels","epoch_block_id", eb_i);
        reorder("epoch_notes","epoch_block_id", eb_i);
        reorder("epoch_block_notes","epoch_block_id", eb_i);


        auto eg_i = getOrder<char16_t>("epoch_groups", "epoch_group_start_time");
        reorder("epochs","epoch_group_id", eg_i);
        reorder("epoch_blocks","epoch_group_id", eg_i);
        reorder("epoch_groups","epoch_group_id", eg_i);
        reorder("channels","epoch_group_id", eg_i);
        reorder("electrodes","epoch_group_id", eg_i);
        reorder("epoch_channels","epoch_group_id", eg_i);
        reorder("epoch_notes","epoch_group_id", eg_i);
        reorder("epoch_block_notes","epoch_group_id", eg_i);
        reorder("epoch_group_notes","epoch_group_id", eg_i);

    }

    template<typename T>
    std::vector<size_t> getOrder(std::string structname, std::string field) {
        //https://stackoverflow.com/questions/17074324

        //gets the sort order of the structure by a specified field
        StructArray s = std::move(key[0][structname]);
        std::vector<size_t> i(s.getNumberOfElements());
        std::iota(i.begin(),i.end(), 0);
        std::sort(i.begin(), i.end(), [&](std::size_t j, std::size_t k) {
            TypedArray<T> d1 = s[j][field];
            TypedArray<T> d2 = s[k][field];
            for (auto i=0; i < d1.getNumberOfElements(); i++) {
                if (d1[i] < d2[i]) return true;
                else if (d1[i] > d2[i]) return false;
            }
            return false;
        });
        key[0][structname] = std::move(s);
        
        std::vector<size_t> ii(i.size());
        for (auto j=0; j<ii.size(); j++) {
            ii[i[j]] = j;
        }
        return ii;
        
    }

    void reorder(std::string structname, std::string field, std::vector<size_t> ind) {
        // std::cout << "Changing " << structname << "[" << field << "]" << std::endl; 
        if (key[0][structname].isEmpty()) return;
        StructArray s = std::move(key[0][structname]);
        for (auto i=0; i < s.getNumberOfElements(); i++) {
            TypedArray<uint64_t> old_ind = s[i][field];
            s[i][field] = factory.createScalar(ind[old_ind[0] - 1] + 1);
        }
        key[0][structname] = std::move(s);
    }

    void throwError(std::string message) {
        matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar(message)}));
    }
};

class MexFunction : public matlab::mex::Function {
public:
    void operator()(ArgumentList outputs, ArgumentList inputs) {
        checkArguments(outputs, inputs);
        CharArray fname = inputs[0];
        Parser(fname.toAscii(), outputs, getEngine());
        
    }
    
    void checkArguments(ArgumentList outputs, ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        if (inputs.size() != 1) {
            matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar("Requires one input.")}));
        }
        
        if (outputs.size() != 1) {
            matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar("Requires one output.")}));
        }
        
        if (inputs[0].getType() != ArrayType::CHAR) {
            matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar("Input must be a char array.")}));
        }
    }
};
