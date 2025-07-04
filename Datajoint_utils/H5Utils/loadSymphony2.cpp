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
#include <exception>
#include <string>

#ifdef VERBOSE
#define DEBUGPRINT(x) std::cout << x << std::endl
#else
#define DEBUGPRINT(x)
#endif

#define EPOCH_OFFSET 621355968000000000

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
    // buffer_ptr_t<uint8_t> ptr;
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



void attr_op(H5::H5Location &loc, const std::string attr_name,
            void *operator_data) {
    DEBUGPRINT(attr_name);
}

ArrayFactory factory;
class Parser {
    private:
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr;
        std::unordered_set<haddr_t> addrs;
        StructArray key = factory.createStructArray({1,1},
        {"experiment","calibration","epoch_groups","epoch_blocks","epochs",
        "channels","electrodes","epoch_channels",
        "sources","retinas","cells","cell_pairs",
        "brains","brain_slices","brain_cells","brain_electrodes",
        "experiment_notes","source_notes",
        "epoch_group_notes","epoch_block_notes","epoch_notes"}
        );
        // CharArray fname;
        std::string fname;
        std::string lastDevice;

        std::unordered_map<std::string, std::pair<symphony_resource,buffer_ptr_t<uint8_t>>> resources;
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
            DEBUGPRINT("Debug printing enabled.");
            #ifdef MATLAB_DEBUGGING
                std::cout << "Running in debug mode. Some features are disabled." << std::endl;
            #endif
            data.insertMember("quantity", 0, H5::PredType::NATIVE_DOUBLE);
            units.insertMember("units", 0, H5::DataType(H5T_STRING, 10));
            
            time_type.insertMember("ticks", HOFFSET(note_time, ticks), H5::PredType::NATIVE_LLONG);

            note_type.insertMember("time", HOFFSET(note_data, entry_time), time_type);
            note_type.insertMember("text", HOFFSET(note_data, text), H5::StrType(0,H5T_VARIABLE));
            
            H5::H5File file;
            try {
                file = H5::H5File(fpath.c_str(), H5F_ACC_RDONLY);
            } catch ( const H5::Exception e) {
                matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar("Error loading symphony .h5 file. Ensure the file name ends in '.h5' and is located in your RAW_DATA folder.")}));
            }
            DEBUGPRINT("Opened file");            
            
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
            DEBUGPRINT("Recursing through file");            
            recurse(file);

            DEBUGPRINT("Closing file");
            file.close();

            DEBUGPRINT("Sorting epochs");
            sortEpochs();

            DEBUGPRINT("Mapping resources");
            mapResources();

            DEBUGPRINT("Assigning cell pairs");
            mapCellPairs();

            output[0] = std::move(key);
        }

        template <class T>
    void recurse(T parent, const char* parent_type = "") {
        try {
            for (auto i=0; i<parent.getNumObjs(); i++) {
                DEBUGPRINT("Getting object #" << i);
                auto name = parent.getObjnameByIdx(i);
                if (parent.childObjType(name) == H5O_TYPE_DATASET) {
                } else if (parent.childObjType(name) == H5O_TYPE_GROUP) {
                    auto group = parent.openGroup(name);
                    DEBUGPRINT("Opened object " << name);
                    H5O_info1_t info;
                    H5Oget_info2(group.getLocId(), &info, H5O_INFO_BASIC);
                    if (!addrs.count(info.addr)) {
                        addrs.insert(info.addr);
                        bool do_recurse = true;
                        auto group_type = name.substr(0,name.find("-")); //note the uuid...
                        switch (str2int(group_type.c_str())) {
                            DEBUGPRINT("Parsing group " << group_type);
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
                    DEBUGPRINT("Done with group " << name);
                }
            }
        } catch( const H5::DataSetIException e) {
            H5::Exception::printErrorStack();
            std::string msg;
            matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar(msg + "Error reading H5 DataSet\nError in H5 library function " + e.getFuncName() + ":\n\t" + e.getDetailMsg())}));
        } catch ( const H5::Exception e ) {
            H5::Exception::printErrorStack();
            std::string msg;
            matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar(msg + "Error in H5 library function " + e.getFuncName() + ":\n\t" + e.getDetailMsg())}));
        } catch( const std::exception e) {
            std::string msg;
            std::cerr << e.what() << std::endl;
            matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar(msg + "Unknown error when parsing H5 file: " + e.what())}));
        } catch (...) {
            std::string msg;
            matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar(msg + "Unknown error when parsing H5 file. No additional information available.")}));
        }
    }

    void parseExperiment(H5::Group experiment) {
        StructArray s = std::move(key[0]["experiment"]);
        if (!s[0]["experiment_start_time"].isEmpty()) throwError("multiple experiments!");
        
        parseDateTime(experiment, s[0]["experiment_start_time"], s[0]["experiment_end_time"]);        

        H5::Attribute attr;

        attr = experiment.openAttribute("startTimeDotNetDateTimeOffsetTicks");
        DEBUGPRINT("Reading attribute start time");
        attr.read(H5::PredType::NATIVE_LLONG, &experiment_date);
        experiment_date = (experiment_date - EPOCH_OFFSET) / 10000; //milliseconds
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
        
        buffer_ptr_t<uint8_t> buffer = factory.createBuffer<uint8_t>(n_samples);
        
        DEBUGPRINT("Reading symphony resource into " << n_samples << " bytes");
        DEBUGPRINT("Actual size: " << space.getSimpleExtentNpoints() << " points, (is simple? " << space.isSimple() << " ), " << space.getSimpleExtentNdims() << " dims");
        DEBUGPRINT("Required bytes for dataset: " << ds.getInMemDataSize());
        #ifndef MATLAB_DEBUGGING
            DEBUGPRINT("Reading as std_u8le");
            ds.read(buffer.get(), H5::PredType::STD_U8LE);
        #endif
        
        
        // symphony_resource data = {parseStrAttr(resource, "name").toAscii(), n_samples};
        symphony_resource data;
        data.name = name;
        // data.ptr = std::move(buffer);
        data.size = n_samples;
        resources.insert({
            resource_uuid,
            std::pair<symphony_resource,buffer_ptr_t<uint8_t>>({
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
        DEBUGPRINT("Converting resources to matlab objects");
        DEBUGPRINT("Errors can occur if path is not configured properly");
        DEBUGPRINT("Consider the following:");
        DEBUGPRINT("\t> cd(userpath)");
        DEBUGPRINT("\t> system('git clone --recurse-submodules https://github.com/Schwartz-AlaLaurila-Labs/sa-labs-extension')");
        DEBUGPRINT("\t> system('git clone --recurse-submodules https://github.com/symphony-das/symphony-matlab')");
        DEBUGPRINT("... and add the resulting directories (with subfolders) to path.");        
        
        for (auto iter = resources.begin(); iter != resources.end(); iter++) {
            // c[i][0] = factory.createCharArray(iter->first); //uuid
            cKeys[i] = factory.createCharArray(iter->second.first.name); //name
            auto temp = factory.createArrayFromBuffer({iter->second.first.size},std::move(iter->second.second)); //buffer data
            
            #ifndef MATLAB_DEBUGGING
            DEBUGPRINT("Converting resource '" << iter->second.first.name << "'");
            cVals[i] = matlabPtr->feval(u"getArrayFromByteStream", {temp});
            #endif
            i++;
        }
        DEBUGPRINT("Done converting resources");   

        key[0]["calibration"] = std::move(matlabPtr->feval(u"containers.Map", {cKeys, cVals}));
    }

    void mapCellPairs() {
        if (key[0]["cell_pairs"].getNumberOfElements()) {
            StructArray cells = std::move(key[0]["cells"]);
            StructArray electrodes = std::move(key[0]["electrodes"]);
            StructArray pairs = std::move(key[0]["cell_pairs"]);
        
            for (Reference<Struct> pair : pairs) {

                DEBUGPRINT("Testing pair...");
                size_t cell_1 = pair["cell_1_id"][0];
                size_t cell_2 = pair["cell_2_id"][0];

                size_t src = pair["source_id"][0];

                size_t matches = 0;

                for (auto elem : cells) {
                    // matlab::data::Array cell_i = elem["cell_number"];
                    size_t cell_i = elem["cell_number"][0];
                    if (cell_i == cell_1) {
                        TypedArray<uint64_t> s_id = elem["source_id"];
                        // pair["cell_1_id"] = factory.createScalar<uint64_t>(s_id[0]);
                        pair["cell_1_id"] = s_id;
                        matches++;

                        
                        DEBUGPRINT("Matched cell 1 ("  << (size_t) s_id[0]<< ")");
                        for (Reference<Struct> electrode : electrodes) {
                            if (((size_t)electrode["source_id"][0] == src) && ((size_t)electrode["cell_id"][0] == 1)){ // this electrode recorded from this cell...
                                DEBUGPRINT("Fixing response");
                                // electrode["cell_id"][0] = factory.createScalar<uint64_t>(s_id[0]);
                                electrode["cell_id"] = s_id;                            
                            }
                        }
                        DEBUGPRINT("Fixed cell 1 responses");
                    }
                    if (cell_i == cell_2) {
                        TypedArray<uint64_t> s_id = elem["source_id"];
                        // pair["cell_2_id"] = factory.createScalar<uint64_t>(s_id[0]);
                        pair["cell_2_id"] = s_id;
                        matches++;

                        DEBUGPRINT("Matched cell 2 ("  << (size_t) s_id[0]<< ")");
                        for (Reference<Struct> electrode : electrodes) {
                            if (((size_t)electrode["source_id"][0] == src) && ((size_t)electrode["cell_id"][0] == 2)){ // this electrode recorded from this cell...
                                DEBUGPRINT("Fixing response");
                                // electrode["cell_id"][0] = factory.createScalar<uint64_t>(s_id[0]);
                                electrode["cell_id"] = s_id;
                            }
                        }
                        DEBUGPRINT("Fixed cell 2 responses");
                    }
                }
                if (matches != 2) throwError("Failed to match cell pairs!"); // should never happen?
            }

            key[0]["cell_pairs"] = std::move(pairs);
            key[0]["electrodes"] = std::move(electrodes);
            key[0]["cells"] = std::move(cells);
        
        }
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
        

        CharArray label = parseStrAttr(epochGroup, "label");
        s[ind]["epoch_group_label"] = label;
        DEBUGPRINT("Read epoch group label: " << label.toAscii());
        
       
        auto source = epochGroup.openGroup("source");
        DEBUGPRINT("Opened epoch group source");
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
        
        #ifndef MATLAB_DEBUGGING
        DEBUGPRINT("Reading response data");
        ds.read(buffer.get(), data);

        // check the units <- 
        hsize_t offset = 0;
        space.selectElements(H5S_SELECT_SET, 1, &offset);
        
        ds.read(unit_i, units, H5::DataSpace::ALL, space);
        #else
        *unit_i = '\0';
        #endif
        
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
                DEBUGPRINT("Units are " << unit_i);
                if (std::strcmp(unit_i, "pA")) {
                    
                    electrode_s[0]["recording_mode"] = factory.createCharArray("Voltage Clamp");
                } else if (std::strcmp(unit_i, "mV")) {
                    electrode_s[0]["recording_mode"] = factory.createCharArray("Current Clamp");
                #ifdef MATLAB_DEBUGGING
                } else electrode_s[0]["recording_mode"] = factory.createCharArray("Unknown");
                #else
                } else throwError("Unknown electrode unit type!");
                #endif                
                electrode_s[0]["hold"] = parseNumericAttr(protocol_params, chan_hold); //need to parse the channel name...
                auto epochGroup = epochBlock.openGroup("epochGroup");
                auto source = epochGroup.openGroup("source");
                auto props = source.openGroup("properties");

                // if (props.attrExists("type")) {
                //     //case cell
                //     electrode_s[0]["cell_id"] = source_id;
                // } else if (props.attrExists("Amplifier 1 cell number")) {
                //     //case cell pair -- we need the corresponding cell...
                //     char index[10];
                //     sprintf(index,"cell_%d_id", electrode_number);
                //     StructArray pairs = std::move(key[0]["cell_pairs"]);
                //     for (auto elem : pairs) {
                //         // TypedArray<uint64_t> cell_i = elem["source_id"];
                //         matlab::data::Array temp = elem["source_id"];
                //         TypedArray<uint64_t> cell_i = temp;
                //         if (cell_i[0] == source_id[0]) {
                //             auto s_id = elem[index];
                //             electrode_s[0]["cell_id"] = factory.createScalar<uint64_t>(s_id[0]);
                //         }
                //     }
                //     key[0]["cell_pairs"] = std::move(pairs);
                    
                // }
                if (props.attrExists("type") || props.attrExists("brain_region")) { //|| props.attrExists("Amplifier 1 cell number")){
                    //case cell or brain cell
                    electrode_s[0]["cell_id"] = source_id; 
                } else if (props.attrExists("Amplifier 1 cell number")) {
                    electrode_s[0]["cell_id"] = factory.createScalar<uint64_t>(electrode_number);                    
                } else if (props.attrExists("Description")){
                    //"other" source, do nothing
                } else if (props.attrExists("orientation")) {
                    //"retina" source, do nothing
                } else if (props.attrExists("slice_thickness")) {
                    //"brain" source, do nothing
                } else if (props.attrExists("slice_notes")) {
                    //"brain_slice" source, do nothing
                } else throwError("Unknown source type!");

                if (props.attrExists("brain_region")){
                    result = matlabPtr->feval(u"vertcat",{std::move(key[0]["brain_electrodes"]), std::move(electrode_s)});
                    key[0]["brain_electrodes"] = std::move(result);
                } else { 
                    result = matlabPtr->feval(u"vertcat",{std::move(key[0]["electrodes"]), std::move(electrode_s)});
                    key[0]["electrodes"] = std::move(result);
                }

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
        #ifndef MATLAB_DEBUGGING
        if (std::strcmp(unit_i, channel_i.units)) throwError("Channel units do not match!");
        #endif
        
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
        DEBUGPRINT("Opened source " << source_uuid);
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
        CharArray label = parseStrAttr(source, "label");
        s[0]["source_label"] = label;
        DEBUGPRINT("Working on source: " << label.toAscii());
        s[0]["source_id"] = factory.createScalar(ind);
        s[0]["file_name"] = factory.createCharArray(fname);
 
        DEBUGPRINT("Adding to sources array");
        StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["sources"]), std::move(s)});
        key[0]["sources"] = std::move(result);
        DEBUGPRINT("Source added to sources array. Getting ready to parse source properties");

        auto props = source.openGroup("properties");
        DEBUGPRINT(props.getNumAttrs() << " properties found");
        if (props.attrExists("DataJoint Identifier") && props.attrExists("eye")) {
            //case new-style retina
            DEBUGPRINT("Parsing Retina");
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
        } else if (props.attrExists("slice_thickness")) {
            //case Brain
            DEBUGPRINT("Parsing Brain");
            s = factory.createStructArray({1},
            {"source_id","animal_id", "thickness", "experimenter", "file_name"});
            s[0]["animal_id"] = parseStr2IntAttr(props, "DataJoint Identifier");
            s[0]["thickness"] = parseNumericAttr(props, "slice_thickness");
            DEBUGPRINT("Thickness done");
            s[0]["experimenter"] = parseStrAttr(props, "recordingBy");
            DEBUGPRINT("Experimenter done");           
            s[0]["source_id"] = factory.createScalar(ind);
            s[0]["file_name"] = factory.createCharArray(fname);
            DEBUGPRINT("File name done");
            
            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["brains"]), std::move(s)});
            key[0]["brains"] = std::move(result);
            DEBUGPRINT("Brain parsed");
            } else if (props.attrExists("genotype")) {
            //case old-style retina
            DEBUGPRINT("Parsing old-style Retina");
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
          } else if (props.attrExists("brain_region")) {
            //case Brain cell
            DEBUGPRINT("Parsing Brain cell");  
            s = factory.createStructArray({1},
            {"file_name","source_id","brain_slice_id","cell_number",
            "brain_region", "notes"});

            s[0]["cell_number"] = parseNumericAttr(props,"number");
            s[0]["brain_region"] = parseStrAttr(props, "brain_region");
            s[0]["notes"] = parseStrAttr(props, "notes");
            s[0]["brain_slice_id"] = factory.createScalar(parent_ind);
            s[0]["source_id"] = factory.createScalar(ind);
            s[0]["file_name"] = factory.createCharArray(fname);
            
            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["brain_cells"]), std::move(s)});
            key[0]["brain_cells"] = std::move(result);    
            DEBUGPRINT("Brain cell parsed");
        } else if (props.attrExists("confirmedType")) {
            //case cell
            DEBUGPRINT("Parsing retinal cell");
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
        } else if (props.attrExists("type")) {
            //non-retinal cell
            DEBUGPRINT("Parsing non-retinal cell");
            s = factory.createStructArray({1},
            {"file_name","source_id","retina_id","cell_number",
            "online_type", "x", "y"});

            s[0]["online_type"] = parseStrAttr(props, "type");
            s[0]["cell_number"] = parseNumericAttr(props,"number");
            s[0]["source_id"] = factory.createScalar(ind);
            s[0]["file_name"] = factory.createCharArray(fname);
            s[0]["x"] = factory.createScalar(NAN);
            s[0]["y"] = factory.createScalar(NAN);
            s[0]["retina_id"] = factory.createScalar(NAN);

            StructArray s2 = factory.createStructArray({1}, {"file_name", "source_id", "entry_time", "text"});
            s2[0]["file_name"] = factory.createCharArray(fname);
            s2[0]["source_id"] = factory.createScalar(ind);
            parseDateTimeField(source, s2[0]["entry_time"], "creationTimeDotNetDateTimeOffsetTicks");  
            s2[0]["text"] = factory.createCharArray(std::string("Experimenter: ") + parseStrAttr(props, "recordingBy").toAscii() + ". " + parseStrAttr(props, "notes").toAscii());            

            // s2[1]["file_name"] = factory.createCharArray(fname);
            // s2[1]["source_id"] = factory.createScalar(ind);
            // parseDateTimeField(source, s2[1]["entry_time"], "creationTimeDotNetDateTimeOffsetTicks");  
            // s2[1]["text"] = factory.createCharArray(std::string("Experimenter: ") + parseStrAttr(props, "recordingBy").toAscii());//factory.createCharArray("");

            key[0]["source_notes"] = matlabPtr->feval(u"vertcat", {std::move(key[0]["source_notes"]), std::move(s2)});
                        
            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["cells"]), std::move(s)});
            key[0]["cells"] = std::move(result);
        } else if (props.attrExists("Amplifier 1 cell number")) {
            DEBUGPRINT("Parsing cell pair");
            //case cell pair
            s = factory.createStructArray({1},
            {"file_name","source_id","cell_1_id","cell_2_id"});
            s[0]["source_id"] = factory.createScalar(ind);
            s[0]["file_name"] = factory.createCharArray(fname);

            #ifdef VERBOSE
            DEBUGPRINT("Attrs are: ");
            props.iterateAttrs((H5::attr_operator_t)attr_op);
            
            // The signature of user_op is void (*)(H5::H5Location&, H5std_string, void*).
            #endif
            
            
            DEBUGPRINT("Reading cell numbers...");
            //we want the cells with the matching number, not source_id...
            // TypedArray<double> cell_1 = parseStr2IntAttr(props, "Amplifier 1 cell number");
            // TypedArray<double> cell_2 = parseStr2IntAttr(props, "Amplifier 2 cell number");
            // TypedArray<double> cell_1 = parseNumericAttr(props, "Amplifier 1 cell number");
            // TypedArray<double> cell_2 = parseNumericAttr(props, "Amplifier 2 cell number");
            // s[0]["cell_1_id"] = factory.createScalar<uint64_t>(cell_1);
            // s[0]["cell_2_id"] = factory.createScalar<uint64_t>(cell_2);    
            // DEBUGPRINT("Cells " << cell_1[0] << " and " << cell_2[0]);

            // s[0]["cell_1_id"] = cell_1;
            // s[0]["cell_2_id"] = cell_2;

            
            s[0]["cell_1_id"] = parseStr2IntAttr(props, "Amplifier 1 cell number");
            s[0]["cell_2_id"] = parseStr2IntAttr(props, "Amplifier 2 cell number");

            // StructArray cells = std::move(key[0]["cells"]);

            // for (auto elem : cells) {
            //     matlab::data::Array temp = elem["cell_number"];
            //     TypedArray<double> cell_i = temp;
            //     if (cell_i[0] == cell_1[0]) {
            //         auto s_id = elem["source_id"];
            //         s[0]["cell_1_id"] = factory.createScalar<uint64_t>(s_id[0]);
            //     }
            //     if (cell_i[0] == cell_2[0]) {
            //         auto s_id = elem["source_id"];
            //         s[0]["cell_2_id"] = factory.createScalar<uint64_t>(s_id[0]);
            //     }
            // }
            // key[0]["cells"] = std::move(cells);

            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["cell_pairs"]), std::move(s)});
            key[0]["cell_pairs"] = std::move(result);

        } else if (props.attrExists("Description")){
           DEBUGPRINT("Ading description");
            //TODO: add a note with the description of this cell!
      } else if (props.attrExists("slice_notes")) {
            //case Brain slice
            DEBUGPRINT("Parsing Brain slice");
            s = factory.createStructArray({1},
            {"source_id", "file_name", "brain_id", "slice_notes"});
            DEBUGPRINT("Source ID");  
            s[0]["source_id"] = factory.createScalar(ind);     
            DEBUGPRINT("FIle name");       
            s[0]["file_name"] = factory.createCharArray(fname);
            DEBUGPRINT("Brain ID");
            s[0]["brain_id"] = factory.createScalar(parent_ind);
            DEBUGPRINT("Slice notes");     
            s[0]["slice_notes"] = parseStrAttr(props, "slice_notes");

            DEBUGPRINT("Params parsed");
            StructArray result = matlabPtr->feval(u"vertcat",{std::move(key[0]["brain_slices"]), std::move(s)});
            key[0]["brain_slices"] = std::move(result);
            DEBUGPRINT("Brain slice parsed");
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
            DEBUGPRINT("Reading experiment parameters attribute.");
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
        
        DEBUGPRINT("Reading attribute: " << attr_name);

        auto attr = group.openAttribute(attr_name);
        auto strtype = attr.getStrType();
        std::string attr_value;

        attr.read(strtype, attr_value);

        DEBUGPRINT("Value was: " << attr_value << " (" << std::stoi(attr_value) << ")");
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
        DEBUGPRINT("Value was: " << attr_value << " (" << std::stoi(attr_value) << ")");
        // strtype.close();
        attr.close();
        return factory.createScalar<double>(std::atof(attr_value.c_str()));
    }

    Array parseNumericAttr(H5::Group group, std::string attr_name) {
        auto attr = group.openAttribute(attr_name);
        double result;
        
        DEBUGPRINT("Reading numeric attribute: " << attr_name);
        attr.read(H5::PredType::NATIVE_DOUBLE, &result);
        DEBUGPRINT("Value was: " << result);
        return factory.createScalar(result);
    }

    void parseLocAttr(H5::Group group, Reference<Array> x, Reference<Array> y) {
        auto attr = group.openAttribute("location");
        double xy[2];
        
        DEBUGPRINT("Reading location attribute");
        attr.read(H5::PredType::NATIVE_DOUBLE, &xy[0]);
        x = factory.createScalar(xy[0]);
        y = factory.createScalar(xy[1]);
    }

    CharArray parseProtocolName(H5::Group group) {
        //can this be a template?
        auto attr = group.openAttribute("protocolID");
        auto strtype = attr.getStrType();
        std::string attr_value;

        
        DEBUGPRINT("Reading protocolID attribute");
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
        DEBUGPRINT("Reading start time attribute (parseDateTime)");
        attr.read(H5::PredType::NATIVE_LLONG, &ticks);
        parseDateTime(ticks, start);

        if(group.attrExists("endTimeDotNetDateTimeOffsetTicks")) {
            attr = group.openAttribute("endTimeDotNetDateTimeOffsetTicks");
            DEBUGPRINT("Reading end timeattribute");
            attr.read(H5::PredType::NATIVE_LLONG, &ticks);
            parseDateTime(ticks, end);
        }        
        
        attr.close();
    }

    void parseDateTimeField(H5::Group group, Reference<Array> start, std::string datetime) {
        //shared timestamp code

        H5::Attribute attr;
        // H5::IntType inttype(H5T_STD_I64LE);
        long long ticks;

        attr = group.openAttribute(datetime);
        DEBUGPRINT("Reading '"  << datetime << "' attribute (parseDateTime)");
        attr.read(H5::PredType::NATIVE_LLONG, &ticks);
        parseDateTime(ticks, start);
        
        attr.close();
    }


    void parseDateTime(time_t ticks, Reference<Array> time_str) {
        //shared timestamp code
        std::stringstream buffer;
        ticks = (ticks - EPOCH_OFFSET) / 10000000;
        buffer << std::put_time(std::gmtime(&ticks), "%Y-%m-%d %H:%M:%S");
        DEBUGPRINT("time string: " << buffer.str());
        time_str = factory.createCharArray(buffer.str());
        DEBUGPRINT("successfully made time string");
    }

    StructArray parseNotes(H5::DataSet notes, hsize_t n_samples, StructArray note_field) {
        
        #ifndef MATLAB_DEBUGGING
        DEBUGPRINT("Reading note data");
        
        note_data* note = new note_data[n_samples];
        notes.read(note, note_type);//, H5::DataSpace::ALL, space);
        
        
        for (auto i=0; i<n_samples; i++) {
            parseDateTime(note[i].entry_time.ticks, note_field[i]["entry_time"]);
            note_field[i]["text"] = factory.createCharArray(note[i].text);
        }

        delete[] note;
        #endif
        return std::move(note_field);
    }

    void parseEpochMilliseconds(H5::Group epoch, Reference<Array> start, Reference<Array> duration) {
        H5::Attribute attr;
        // H5::IntType inttype(H5T_STD_I64LE);
        long long ticks1, ticks2;

        attr = epoch.openAttribute("startTimeDotNetDateTimeOffsetTicks");
        DEBUGPRINT("Reading start time attribute (parseEpochMilliseconds)");
        attr.read(H5::PredType::NATIVE_LLONG, &ticks1);
        //TODO: is something wrong here??
        ticks1 = (ticks1 - EPOCH_OFFSET) / 10000; //milliseconds

        start = factory.createScalar(ticks1 - experiment_date);

        
        attr = epoch.openAttribute("endTimeDotNetDateTimeOffsetTicks");
        DEBUGPRINT("Reading end time attribute");
        attr.read(H5::PredType::NATIVE_LLONG, &ticks2);
        ticks2 = (ticks2 - EPOCH_OFFSET) / 10000; //milliseconds

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
        reorder("brain_electrodes","epoch_block_id", eb_i);
        reorder("epoch_channels","epoch_block_id", eb_i);
        reorder("epoch_notes","epoch_block_id", eb_i);
        reorder("epoch_block_notes","epoch_block_id", eb_i);


        auto eg_i = getOrder<char16_t>("epoch_groups", "epoch_group_start_time");
        reorder("epochs","epoch_group_id", eg_i);
        reorder("epoch_blocks","epoch_group_id", eg_i);
        reorder("epoch_groups","epoch_group_id", eg_i);
        reorder("channels","epoch_group_id", eg_i);
        reorder("electrodes","epoch_group_id", eg_i);
        reorder("brain_electrodes","epoch_group_id", eg_i);
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
