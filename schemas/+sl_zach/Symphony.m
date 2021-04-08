%{
# Master table of fully processed Symphony data for a single recording session
# Recording sessions should enter the database in an 'all-or-none' manner
recording_date: date
->sl.Rig
---
start_time : time   # time that the session was created in Symphony DAS
(experimenter) -> sl.User(user_name)
%}
classdef Symphony < dj.Manual
    properties (Constant)
        RAW_DATA_FOLDER = getenv('RAW_DATA_FOLDER');
        CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
        PREFERENCE_FILES_FOLDER = getenv('PREFERENCE_FILES_FOLDER');
    end
    
    methods(Static)
        function merged_cells = loadMergedCells()
            merged_cells = cellfun(@(x) split(x),...
                splitlines(...
                fileread(sprintf('%sMergedCells.txt',sl_zach.Symphony().PREFERENCE_FILES_FOLDER))...
                ),...
                'UniformOutput',false);
            
        end
    end
    
    methods
        function insert(self, key)
            %key structure:
            %   required: raw_data_rootname
            %   optional, but possibly required if unresolvable:
            %     animal_id
            %     cell_unid
            %     cell_data
            %     orientation %of retina, 'ventral down' or 'unknown'
            raw_data_rootname = unique({key(:).raw_data_rootname});
            if numel(raw_data_rootname) > 1
                error('Only one raw_data_rootname is allowed per insert into Symphony table at this time.')
            end
            if isfield(key,'animal_id') || isfield(key,'cell_data') || isfield(key,'orientation')
                animal_ids = unique([key(:).animal_id]);
                if length(animal_ids) > 1 && (~isfield(key,'cell_data') || ~isfield(key, 'orientation'))
                    error('Must specify animal_id, cell_data, and orientation together.');
                end
                auto_matching = false;
                if count(sl.AnimalEventDeceased & struct('animal_id',arrayfun(@(x) x, animal_ids, 'uniformoutput',false))) ~= length(animal_ids)
                    error('Animals must all be marked as deceased in the database');
                end
            else
                auto_matching = true;
            end
            if isfield(key,'cell_unid')
                cell_create = false;
            else
                cell_create = true;
            end
            
            % rig_name = arrayfun(@(x) x.raw_data_rootname(end), key);
            rig_name = key(1).raw_data_rootname(end);
            [epochs, retinas, recording_date, recording_time, epoch_groups] = sl_zach.Symphony.loadHDF5(raw_data_rootname{1}); %do this for each raw_data_rootname
            %NOTE: recording_date is from symphony wall time, not file name.
            save(sprintf('raw/%s.mat',raw_data_rootname{1}),'epochs','retinas','recording_date','recording_time','epoch_groups');
            return
            
            if ~all(strcmp({retinas(:).orientation}, 'ventral down'))
                if all(cellfun(@isempty, {retinas(:).orientation}))
                    [retinas(:).orientation] = deal('unknown');
                else
                    error('Need to debug!');
                end
            end
            
            experimenter = unique({retinas(arrayfun(@(x) ~isempty(x.experimenter), retinas)).experimenter});
            if numel(experimenter) > 1
                if isfield(key,'experimenter')
                    experimenter = key.experimenter;
                else
                    error('There are multiple experimenters associated with the HDF5 file, but the database only allows one. Please specify the main experimenter in the input key.');
                end
            elseif numel(experimenter) > 0
                experimenter = experimenter{1};
            else
                experimenter = 'Unknown';
            end
            
            if auto_matching
                if numel(retinas)>1
                    error('Multiple retina sources were found in HDF5 file. You must specify the animal_id for each cell_data.');
                end
                f = fetch(...
                    (sl.AnimalEventDeceased * proj(...
                    sl.AnimalEventReservedForSession & sprintf("date='%s'", recording_date) & sprintf("rig_name='%s'", rig_name),...
                    'animal_id->match','event_id->null'))...
                    & '`match`=`animal_id`',...
                    'animal_id');
                if isempty(f)
                    error('No reservation found in database matching this recording! You must specify the animal_id manually, add the reservation to the database, or mark the animal as deceased.');
                elseif length(f) > 1
                    error('Multiple animals were found in the database matching this recording. You must specify the animal_id for each cell_data.');
                else
                    [key(:).animal_id] = deal(f.animal_id); %TODO: is this used?
                    animal_ids = [f.animal_id];
                end
            end
            
            if cell_create
                if count(sl_zach.CellRetina & join(arrayfun(@(x) sprintf('animal_id=%d', x),animal_ids,'uniformoutput',false), ' OR '))
                    error('There are already retinal cells in the database corresponding to animals %s\b\b!\n' +...
                        'You must specify the animal_id and cell_unid for each cell_data.\n'+...
                        'If a cell does not correspond to an existing retinal cell, use cell_unid=0 to automatically assign a cell_unid.',...
                        sprintf('%s, ', animal_ids));
                end
            else
                cell_count = nan;
            end
            
            %now open the cell data file to get the datasets
            files = dir(sprintf('%s%s*.mat', self.CELL_DATA_FOLDER, raw_data_rootname{1}));
            if numel(files) == 0
                warning('No cell data files match the raw data file. Exiting.');
                return
            end
            if auto_matching
                if numel(files) < sum(arrayfun(@(x) numel(x.cells), retinas))
                    warning('There are recorded cells for which no cell data file was found. These will not be added to the database.');
                end
            elseif numel(files) ~= numel(animal_ids)
                error('Number of provided keys does not match number of cell data files.');
            end
            
            if cell_create
                % cell_unid = fetch1(sl_zach.Cell, 'max(cell_unid) -> next');
                cell_unid = sl_zach.Cell().count; %TODO: debug this
            end
            toggle_create = false;
            temp_create = false;
            
            merged_cells = sl_zach.Symphony.loadMergedCells();
            all_params = cell(0,0);
            paramNames = {};
            paramTypes = {};
            nParams = 0;
            
            emp = cell(numel(files),1);
            celldata_keys = struct('datasets',emp,'epochs',emp,'channels',emp,'spikes',emp,'datasetEpochs',emp,'symphony',emp,'cell',emp,'cellRetina',emp);
            
            for n=1:numel(files)
                cell_data = files(n).name(1:end-4);
                load(sprintf('%s%s',self.CELL_DATA_FOLDER,files(n).name),'cellData');
                [cdk, params, ch1_id] = sl_zach.Symphony.processCellData(cellData, epochs, epoch_groups);
                if isempty(cdk)
                    warning('No saved datasets for %s. Nothing will be added to database for this cell.', cell_data);
                    continue
                end
                if isempty(ch1_id)
                   epoch1 = strcmp(arrayfun(@(x) x.data_link{1}, epochs, 'uniformoutput',false),cdk.channels(1).data_link);
                   ch1_id =  [epochs(epoch1).retina epochs(epoch1).cell];
                end
                cdk.cell = [];
                cdk.cellRetina = [];
                emp = cell(0,1);
                cdk.symphony = struct('recording_date',emp,'rig_name',emp,...
                    'cell_unid',emp,...
                    'cell_data',emp,...
                    'position_x',emp,'position_y',emp,...
                    'number_of_epochs',emp,...
                    'online_label',emp...
                    );
                celldata_keys(n) = cdk;
                dups = cellfun(@(x) any(strcmp(x,cell_data) | strcmp(x,sprintf('%s-Ch1', cell_data))), merged_cells); %TODO: ch2?
                if any(dups) && ~strcmp(cell_data, merged_cells{dups}{1})
                    matching_ind = strcmp(arrayfun(@(x) x.name(1:end-4), files, 'UniformOutput',false), merged_cells{dups}{1});
                    cell_unid = celldata_keys(matching_ind).cell.cell_unid;
                    celldata_keys(matching_ind).symphony.number_of_epochs = celldata_keys(matching_ind).symphony.number_of_epochs + numel(cellData.epochs);
                    if cell_create
                        toggle_create = true;
                        cell_create = false;
                    elseif keys(strcmp({keys(:).cell_data}, cell_data)).cell_unid ~= cell_unid
                        error('Encountered a group of cells in MergedCells.txt, but tried to assign different cell_unids!');
                    end
                    cell_data = merged_cells{dups}{1};
                else
                    if cell_create
                        cell_unid = cell_unid + 1;
                    else
                        cell_unid = keys(strcmp({keys(:).cell_data}, cell_data)).cell_unid;
                        if cell_unid == 0
                            if isnan(cell_count)
                                cell_count = sl_zach.Cell.count + 1;
                            else
                                cell_count = cell_count + 1;
                            end
                            cell_unid = cell_count;
                            temp_create = true;
                        end
                    end
                    loc = retinas(ch1_id(1)).cells(ch1_id(2)).location;
                    if isempty(loc)
                        loc = [0,0];
                    end
                    celldata_keys(n).symphony = struct('recording_date',recording_date,'rig_name',rig_name,...
                        'cell_unid',cell_unid,...
                        'cell_data',cell_data,...
                        'position_x',loc(1),'position_y',loc(2),...
                        'number_of_epochs',numel(cellData.epochs),...
                        'online_label',retinas(ch1_id(1)).cells(ch1_id(2)).online_label...
                        );
                end
                
                if auto_matching
                    animal_id = animal_ids;
                else
                    animal_id = keys(strcmp({keys(:).cell_data}, files(n).name(1:end-4))).animal_id;
                end
                
                if cell_create || temp_create
                    temp_create = false;
                    celldata_keys(n).cell = struct('cell_unid',cell_unid,'animal_id',animal_id);
                    celldata_keys(n).cellRetina = struct('cell_unid',cell_unid,'animal_id',animal_id,'side',retinas(ch1_id(1)).eye);
                end
                
                [celldata_keys(n).datasets(:,1).cell_unid] = deal(cell_unid);
                [celldata_keys(n).datasets(:).recording_date] = deal(recording_date);
                [celldata_keys(n).datasets(:).rig_name] = deal(rig_name);
                
                [celldata_keys(n).epochs(:).recording_date] = deal(recording_date);
                [celldata_keys(n).epochs(:).rig_name] = deal(rig_name);
                
                [celldata_keys(n).channels(:).recording_date] = deal(recording_date);
                [celldata_keys(n).channels(:).rig_name] = deal(rig_name);
                
                [celldata_keys(n).spikes(:).recording_date] = deal(recording_date);
                [celldata_keys(n).spikes(:).rig_name] = deal(rig_name);
                
                [celldata_keys(n).datasetEpochs(:,1).cell_unid] = deal(cell_unid);
                [celldata_keys(n).datasetEpochs(:).recording_date] = deal(recording_date);
                [celldata_keys(n).datasetEpochs(:).rig_name] = deal(rig_name);
                
                has_ch2 = arrayfun(@(x) ~isempty(x.data_link), celldata_keys(n).channels(:,2));
                ch2 = sprintf('%s-Ch2', cell_data);
                dups = cellfun(@(x) any(strcmp(x,ch2)), merged_cells);
                if any(dups)
                    matching_ind = strcmp(arrayfun(@(x) x.name(1:end-4), files, 'UniformOutput',false), merged_cells{dups}{1});
                    celldata_keys(matching_ind).symphony.number_of_epochs = celldata_keys(matching_ind).symphony.number_of_epochs + numel(cellData.epochs);
                    cell_unid = celldata_keys(matching_ind).cell.cell_unid;
                elseif any(has_ch2)
                    if cell_create || toggle_create
                        cell_unid = cell_unid + 1;
                        celldata_keys(n).cell = cat(1,celldata_keys(n).cell, struct('cell_unid',cell_unid,'animal_id',animal_id));
                        celldata_keys(n).cellRetina = cat(1,celldata_keys(n).cellRetina, struct('cell_unid',cell_unid,'animal_id',animal_id,'side',retinas(ch1_id).eye));
                    else
                        cell_unid = keys(strcmp({keys(:).cell_data}, ch2)).cell_unid;
                        if cell_unid == 0
                            if isnan(cell_count)
                                cell_count = sl_zach.Cell.count + 1;
                            else
                                cell_count = cell_count + 1;
                            end
                            cell_unid = cell_count;
                            celldata_keys(n).cell = cat(1,celldata_keys(n).cell, struct('cell_unid',cell_unid,'animal_id',animal_id));
                            celldata_keys(n).cellRetina = cat(1,celldata_keys(n).cellRetina, struct('cell_unid',cell_unid,'animal_id',animal_id,'side',retinas(ch1_id).eye));
                        end
                    end
                    celldata_keys(n).symphony = cat(1,celldata_keys(n).symphony, struct('recording_date',recording_date,'rig_name',rig_name,...
                        'cell_unid',cell_unid,...
                        'cell_data',ch2,...
                        'position_x',0,'position_y',0,...
                        'number_of_epochs',numel(cellData.epochs),...
                        'online_label',retinas(ch1_id(1)).cells(ch1_id(2)).online_label...
                        ));
                end
                %now remove blanks
                if any(has_ch2)
                    [celldata_keys(n).datasets(:,2).cell_unid] = deal(cell_unid);
                    [celldata_keys(n).datasetEpochs(:,2).cell_unid] = deal(cell_unid);
                else
                    celldata_keys(n).datasets(:,2) = [];
                    celldata_keys(n).datasetEpochs(:,2) = [];
                end
                
                no_ch2 = find(~has_ch2);
                celldata_keys(n).channels(no_ch2 + numel(celldata_keys(n).epochs)) = [];
                celldata_keys(n).spikes(no_ch2 + numel(celldata_keys(n).epochs)) = [];
                celldata_keys(n).spikes(cellfun(@isempty, {celldata_keys(n).spikes(:).count})) = [];
                
                %expand the parameters
                newParams = cellfun(@(x) ~any(strcmp(x,paramNames)),{params(:,1).Name});
                if any(newParams)
                    paramNames = cat(1,paramNames,{params(newParams,1).Name}');
                    paramTypes = cat(1,paramTypes,{params(newParams,1).Type}');
                    all_params = cat(1,all_params, repmat({nan},nnz(newParams), size(all_params,2)));
                    %  all_params(nParams+1 :nParams+nnz(newParams),:).Value] = deal(nan);
                    % [all_params(nParams+1 :nParams+nnz(newParams),:).Type] = subsref(repmat({params(newParams,1).Type}',1,numel(celldata_keys(n).epochs)),ss);
                    % [all_params(nParams+1 :nParams+nnz(newParams),:).Name] = subsref(repmat({params(newParams,1).Name}',1,numel(celldata_keys(n).epochs)),ss);
                    nParams = length(paramNames);
                end
                epochs_so_far = size(all_params,2);
                all_params = reshape(cat(2,all_params,repmat({nan}, nParams, size(params,2))),[],1);
                [all_params{sub2ind(...
                    [nParams, epochs_so_far+size(params,2)],...
                    repmat(cellfun(@(x) find(strcmp(x,paramNames)),{params(:,1).Name})',1,size(params,2)),...
                    repmat(epochs_so_far+1 : epochs_so_far+size(params,2),size(params,1), 1)...
                    )}] = deal(params(:).Value);
                all_params = reshape(all_params, nParams,[]);
                
                if toggle_create
                    toggle_create = false;
                    cell_create = true;
                end
            end
            
            % at this point, we have everything
            epochs = vertcat(celldata_keys(:).epochs); %rename... i think it's okay...
            datasets = vertcat(celldata_keys(:).datasets);
            channels = horzcat(celldata_keys(:).channels)';
            spikes = horzcat(celldata_keys(:).spikes)';
            datasetEpochs = vertcat(celldata_keys(:).datasetEpochs);
            symphonyCell = vertcat(celldata_keys(:).symphony);
            animalCell = vertcat(celldata_keys(:).cell);
            cellRetina = vertcat(celldata_keys(:).cellRetina);
            
            %make a few corrections
            [epochs(strcmp({epochs(:).protocol_name},'ImageCyler')).protocol_name] = deal('ImageCycler');
            
            [all_params, paramNames, unhashed] = sl_zach.SymphonySettings.clean_parameters(all_params, paramNames);
            
            c = dj.conn;
            try
                c.cancelTransaction(); %anything pending will be thrown out, ideally
                c.startTransaction();
                
                ss = substruct('{}',{':'});
                [indices, remainingKeysProtocols, ~] = sl_zach.SymphonyProtocolSettings().addParameterGroup(all_params, paramNames, unhashed);
                [epochs(:).protocol_id] = subsref(num2cell(indices), ss);
                
                [indices, remainingKeysEpochs, ~] = sl_zach.SymphonyEpochSettings().addParameterGroup(all_params, paramNames, unhashed);
                [epochs(:).epoch_id] = subsref(num2cell(indices), ss);
                
                [indices, remainingKeysProjector, ~] = sl_zach.SymphonyProjectorSettings().addParameterGroup(all_params, paramNames);
                [epochs(:).projector_id] = subsref(num2cell(indices), ss);
                
                remainingKeys = remainingKeysProtocols & remainingKeysEpochs & remainingKeysProjector;
                paramsRemaining = paramNames(remainingKeys);
                exclude = sl_zach.SymphonyParameterExclude().fetchn('parameter_name');
                paramsRemaining = paramsRemaining(~ismember(paramsRemaining, exclude));
                
                if numel(paramsRemaining)
                    error('There are saved Symphony parameters (%s\b\b) that are not present in the database! They must be manually added (with care).', sprintf('%s, ', paramsRemaining{:}));
                end
                
                if cell_create
                    sl_zach.Cell().insert(animalCell);
                    %TODO: sl.Eye().insert(...);
                    sl_zach.CellRetina().insert(cellRetina);
                end
                insert@dj.Manual(self,struct(...
                    'recording_date',recording_date,...
                    'start_time',recording_time,...
                    'rig_name',rig_name,...
                    'experimenter',experimenter...
                    )); %TODO: start_time?
                sl_zach.SymphonyCell().insert(symphonyCell);
                sl_zach.SymphonyCellDataset().insert(datasets);
                sl_zach.SymphonyEpoch().insert(epochs);
                sl_zach.SymphonyEpochChannel().insert(channels);
                sl_zach.SymphonySpikeTrain().insert(spikes);
                sl_zach.SymphonyCellDatasetChannel().insert(datasetEpochs);
                c.commitTransaction();
            catch ME
                c.cancelTransaction();
                rethrow(ME);
            end
        end
    end
    
    methods (Static, Access=private)
        function [epochs,retinas,recording_date,recording_time,epochGroups] = loadHDF5(raw_data_root)
            %     fpath = sprintf('%s%s.h5', self.RAW_DATA_FOLDER, raw_data_root);
            files = dir(sprintf('%s%s*', sl_zach.Symphony().RAW_DATA_FOLDER, raw_data_root));
            files = cellfun(@(x) sprintf('%s%s',sl_zach.Symphony().RAW_DATA_FOLDER, x), {files(:).name},'uniformoutput',false);
            version = cellfun(@(x) int8(safeh5Version(x)), files,'uniformoutput',false);
            bad = cellfun(@isempty, version) | contains(files,'Test');
%             files(bad) = [];
            [version{bad}] = deal(int8(-1));
            version = cell2mat(version);
            %we will just ignore any missing... they hopefully don't have
            %cell data since they're just empty
            
%             version = cellfun(@(x) x.Attributes(1).Value, hinfo);
            if nnz(version == 2) > 1
                error('There are multiple Symphony 2 files associated with the raw_data_rootname.');
            end
            %what about symphony 1?
            
            if any(version == 1)
                %if version == -1, we assume symphony 1... but likely empty
                %anyways
                [epochs, retinas, recording_date, recording_time, epochGroups] = parseSymphony1(cellfun(@(x) safeh5LoadS1(x), files(version ~= 2)), files(version ~= 2));
            end
            
            if any(version == 2)
                [epochs2, retinas2, recording_date2, recording_time2, epochGroups2] = parseSymphony2(h5info(files{version == 2},'/'), files{version == 2});
                ss = substruct('{}',{':'});
                [epochs2(:).protocol] = deal(subsref(arrayfun(@(x) epochGroups2(x.group).blocks(x.block).protocol, epochs2, 'uniformoutput', false), ss));
                [epochs2(:).retina] = deal(subsref(arrayfun(@(x) epochGroups2(x.group).retina, epochs2, 'uniformoutput', false), ss));
                [epochs2(:).cell] = deal(subsref(arrayfun(@(x) epochGroups2(x.group).cell, epochs2, 'uniformoutput', false), ss));
                
                if any(version == 1)
                   epochGroups = epochGroups2;
                   retinas = horzcat(retinas2, retinas); %but can we join them, possibly???
                   [epochs(:).retina] = deal(subsref(arrayfun(@(x) x+numel(retinas2), [epochs(:).retina], 'uniformoutput',false), ss));
                   epochs = vertcat(epochs2, epochs);
                   recording_date = datestr(min([datetime(recording_date) datetime(recording_date2)]),'YYYY-mm-DD');
                   recording_time = datestr(min([datetime(recording_time) datetime(recording_time2)]),'HH:MM:SS');
                   
                else
                    epochs = epochs2;
                    retinas = retinas2;
                    recording_date = recording_date2;
                    recording_time = recording_time2;
                    epochGroups = epochGroups2;
                end
            end
            
            
            function v = safeh5Version(file)
                try
                    v = h5readatt(file, '/','version');
                catch ME
                    if strcmp(ME.identifier, 'MATLAB:imagesci:hdf5lib:fileOpenErr') || strcmp(ME.identifier, 'MATLAB:imagesci:hdf5lib:libraryError')
                        v = [];
                    else
                       rethrow(ME); 
                    end
                end
            end
            
            function h = safeh5LoadS1(file)
               %for symphony 1
               try
                   h = hdf5info(file,'ReadAttributes',false);
               catch ME
                   if ~strcmp(ME.identifier, 'MATLAB:imagesci:deprecatedHDF5:libraryError')
                      rethrow(ME);
                      % some files are corrupted... maybe because of an
                      % issue at experiment time?
                      % but we still want to access cell data from other
                      % files... so just assume that there's no
                      % corresponding cell data to the corrupted file?
                   end
                   emp = cell(1,1);
                   h = struct('Filename',emp,'LibVersion',emp,'Offset',emp,'FileSize',emp,'GroupHierarchy',emp);
               end
            end
            
            function hinfo = h5goto(hinfo, dest)
                next = cellfun(@(x) contains(dest, x), {hinfo.Groups(:).Name});
                if strcmp(hinfo.Groups(next).Name, dest)
                    hinfo = hinfo.Groups(next);
                    return
                end
                hinfo = h5goto(hinfo.Groups(next), dest);
            end
            
            function attr = get_attr(group, attr_name)
                attr = h5readatt(group.Filename, group.Name, attr_name);
            end
            
            function [epochs,retinas,recording_date, recording_time,epochGroups] = parseSymphony2(hinfo, file)
                rinfo = cell2mat(arrayfun( @(x) h5goto(hinfo, x.Value{1}), hinfo.Groups.Groups(5).Links, 'UniformOutput', false));
                
                NRetinas = numel(rinfo);
                emp = cell(NRetinas, 1);
                retinas = struct('Name',emp, 'genotype',emp, 'orientation', emp, 'experimenter', emp, 'eye', emp, 'cells', emp);
                
                recording_datetime = min(arrayfun(@(x) datetime(...
                    uint64(x.Attributes(strcmp({x.Attributes(:).Name},'creationTimeDotNetDateTimeOffsetTicks')).Value),...
                    'ConvertFrom','.net',...
                    'timezone',num2str(x.Attributes(strcmp({x.Attributes(:).Name},'creationTimeDotNetDateTimeOffsetOffsetHours')).Value)...
                    ), rinfo));
                recording_time = datestr(recording_datetime,'HH:MM:SS');
                recording_date = datestr(recording_datetime,'YYYY-mm-DD');
                
                NEpochGroups = sum(arrayfun(@(x) length(x.Groups(2).Groups), hinfo.Groups));
                emp = cell(NEpochGroups,1);
                epochGroups = struct('uuid',emp,'label',emp,'blocks',emp,'retina',emp,'cell',emp,'cell_label',emp);
                [epochGroups(:).uuid]=deal('');
                group_count = 0;
                cell_count = 0;
                epoch_count = 0;
                
                epochs = struct('parameters',{},'data_link',{},'units',{},'sample_rate',{},'start_time',{},'duration',{},'group',{},'block',{});
                for n = 1:NRetinas
                    properties = endsWith({rinfo(n).Groups(:).Name},'properties');
                    attr = cat(1,rinfo(n).Groups(properties).Attributes,rinfo(n).Attributes);
                    
                    retinas(n).Name = attr(strcmp({attr(:).Name}, 'label')).Value;
                    retinas(n).genotype = attr(strcmp({attr(:).Name}, 'genotype')).Value;
                    retinas(n).eye = attr(strcmp({attr(:).Name}, 'eye')).Value;
                    orientation = strcmp({attr(:).Name}, 'orientation');
                    if any(orientation)
                        retinas(n).orientation = attr(orientation).Value;
                    else
                        retinas(n).orientaiton = 'Unknown';
                    end
                    if length(rinfo(n).Groups(2).Attributes) > 3
                        retinas(n).experimenter = rinfo(n).Groups(2).Attributes(4).Value;
                    end
                    
                    cinfo = vertcat(...
                        cell2mat(arrayfun(@(x) h5goto(hinfo, x.Value{1}),rinfo(n).Groups(4).Links, 'UniformOutput', false))',...
                        rinfo(n).Groups(4).Groups...
                        );
                    
                    %c1: rinfo(1).Groups(4).Links(1)
                    %c2: rinfo(1).Groups(4).Groups(1)
                    
                    nCells = numel(cinfo);
                    emp = cell(nCells, 1);
                    retinas(n).cells = struct('Name', emp, 'online_label', emp, 'location', emp);
                    
                    for m = 1:nCells
                        retinas(n).cells(m).Name = cinfo(m).Attributes(strcmp({cinfo(m).Attributes(:).Name},'label')).Value;
                        properties = arrayfun( @(x) endsWith(x.Name,'properties'), cinfo(m).Groups);
                        attr = cinfo(m).Groups(properties).Attributes;
                        retinas(n).cells(m).online_label = attr(strcmp({attr(:).Name}, 'type')).Value;
                        
                        location = strcmp({attr(:).Name}, 'location');
                        if nnz(location)==1
                            retinas(n).cells(m).location = attr(location).Value;
                        end
                        number = attr(strcmp({attr(:).Name}, 'number')).Value;
                        retinas(n).cells(m).name_full = sprintf('%d%s',number, retinas(n).Name);
                        
                        cell_count = cell_count + 1;
                        for l = 1:numel(cinfo(m).Groups(1).Links)
                            epochGroup = h5goto(hinfo, cinfo(m).Groups(1).Links(l).Value{1});
                            uuid = epochGroup.Attributes(1).Value;
                            if ~ismember(uuid,{epochGroups(:).uuid})
                                label = strcmp({epochGroup.Attributes(:).Name},'label');
                                g = struct('uuid',uuid,'label',epochGroup.Attributes(label).Value,'retina',n,'cell',cell_count,'cell_label',retinas(n).cells(m).name_full);
                                
                                %now we get to the epoch blocks:
                                nBlocks = numel(epochGroup.Groups(1).Groups);
                                emp = cell(nBlocks, 1);
                                g.blocks = struct('protocol',emp,'parameters',emp);
                                group_count = group_count + 1;
                                for k = 1:nBlocks
                                    block = epochGroup.Groups(1).Groups(k);
                                    protocol = split(block.Attributes(strcmp({block.Attributes(:).Name},'protocolID')).Value,'.');
                                    g.blocks(k).protocol =  protocol{end};
                                    parameters = endsWith({block.Groups(:).Name},'protocolParameters');
                                    g.blocks(k).parameters = struct('Name', {block.Groups(parameters).Attributes(:).Name}', 'Value',...
                                        {block.Groups(parameters).Attributes(:).Value}', 'Type', arrayfun(@(x) x.Datatype.Class, block.Groups(parameters).Attributes, 'UniformOutput',false));
                                    
                                    %block.Groups(2).Attributes;
                                    nEpochs = numel(block.Groups(1).Groups);
                                    emp = cell(nEpochs, 1);
                                    epochs = cat(1,epochs,struct('parameters',emp,'data_link',emp,'units',emp, 'sample_rate',emp,'start_time',emp,'duration',emp,'group',emp,'block',emp));
                                    for j = 1:nEpochs
                                        epoch_count = epoch_count + 1;
                                        epoch = block.Groups(1).Groups(j);
                                        parameters = (endsWith({epoch.Groups(:).Name},'properties') | endsWith({epoch.Groups(:).Name},'protocolParameters')) & ~arrayfun(@(x) isempty(x.Attributes), epoch.Groups);
                                        if any(parameters)
                                            epochs(epoch_count).parameters = vertcat(cell2mat(arrayfun(@(x) struct(...
                                                'Name', {x.Attributes(:).Name}',...
                                                'Value', {x.Attributes(:).Value}',...
                                                'Type',arrayfun(@(y) y.Datatype.Class, x.Attributes, 'UniformOutput',false)),...
                                                epoch.Groups(parameters), 'UniformOutput',false)));
                                        end
                                        
                                        if ~isempty(epoch.Groups(2).Attributes)
                                            epochs(epoch_count).parameters = struct('Name', {epoch.Groups(2).Attributes(:).Name}',...
                                                'Value', {epoch.Groups(2).Attributes(:).Value}',...
                                                'Type',arrayfun(@(x) x.Datatype.Class, epoch.Groups(2).Attributes, 'UniformOutput',false));
                                        end
                                        %epoch.Groups(2).Attributes;
                                        responses = endsWith({epoch.Groups(:).Name},'responses');
                                        amps = contains({epoch.Groups(responses).Groups(:).Name},'Amp');
                                        
                                        epochs(epoch_count).data_link = arrayfun(@(x) sprintf('%s/data',x.Name), epoch.Groups(responses).Groups(amps),'uniformoutput',false);
                                        epochs(epoch_count).units = cellfun(@(x) deblank(h5read(file, x,1,1).units'), epochs(epoch_count).data_link, 'uniformoutput',false);
                                        
                                        sr = strcmp({epoch.Groups(responses).Groups(find(amps, 1)).Attributes(:).Name}, 'sampleRate');
                                        epochs(epoch_count).sample_rate = epoch.Groups(responses).Groups(find(amps, 1)).Attributes(sr).Value;
                                        
                                        start_time = strcmp({epoch.Attributes(:).Name}, 'startTimeDotNetDateTimeOffsetTicks');
                                        time_zone = strcmp({epoch.Attributes(:).Name}, 'startTimeDotNetDateTimeOffsetOffsetHours');
                                        
                                        epochs(epoch_count).start_time = milliseconds(datetime(uint64(epoch.Attributes(start_time).Value),'convertfrom','.net','timezone',num2str(epoch.Attributes(time_zone).Value))-recording_date);
                                        epochs(epoch_count).duration = (epoch.Attributes(4).Value - epoch.Attributes(2).Value)/epochs(epoch_count).sample_rate;
                                        epochs(epoch_count).group = group_count;
                                        epochs(epoch_count).block = k;
                                        %epoch.Groups(3).Groups(1).sampleRate ...
                                        %sampleRateUnits,
                                        %inputTimeDotNetDateTimeOffsetTicks
                                    end
                                    
                                end
                                epochGroups(group_count) = g;
                            else
                                warning('skipped an epoch group unexpectedly!');
                            end
                        end
                    end
                end
                % epochs = cell2mat(arrayfun( @(x)cell2mat({x.blocks(:).epochs}'), epochGroups,'uniformoutput',false));
                [~,i] = sort([epochs(:).start_time]);
                epochs = epochs(i);
            end
            
            function [epochs,retinas,recording_date, recording_time,epochGroups] = parseSymphony1(hinfo,files)
                recording_time = cell(numel(hinfo),2);
                retinas = struct('Name',{}, 'genotype', {}, 'orientation', {}, 'experimenter', {}, 'eye', {}, 'cells', {});
                epochs = struct('parameters',{},'data_link',{},'units',{},'sample_rate',{},'start_time',{},'duration',{},'group',{},'block',{},'protocol',{},'retina',{},'cell',{});
                epoch_count = 0;
                epochGroups = [];
                for o=1:numel(hinfo)
                    if isempty(hinfo(o).GroupHierarchy) || isempty(hinfo(o).GroupHierarchy.Groups)
                        recording_time(o,:) = {intmax('uint64'), -1};
                       continue
                    end
                    recording_time(o,:) = {
                        get_attr(hinfo(o).GroupHierarchy.Groups(1),'startTimeDotNetDateTimeOffsetUTCTicks'),...
                        get_attr(hinfo(o).GroupHierarchy.Groups(1),'startTimeUTCOffsetHours')...
                        };
                    for n=1:numel(hinfo(o).GroupHierarchy.Groups)
%                         ruuid = get_attr(hinfo(o).GroupHierarchy.Groups(n),'source');
                        rname = get_attr(hinfo(o).GroupHierarchy.Groups(1).Groups(3),'mouseID');
                        rind = find(strcmp(rname, {retinas(:).Name}));
                        if ~isempty(rind)
                            thisRetina = retinas(rind);
                        else
                            rind = length(retinas) + 1;
                            emp = cell(1,1);
                            thisRetina = struct(...
                                'Name',rname,...
                                'genotype', rname,...
                                'orientation', emp,...
                                'experimenter', emp,...
                                'eye', emp,...
                                'cells', emp);
                            thisRetina.cells = struct('Name',{}, 'online_label',{}, 'location', {});
                        end
                        
                        cname = get_attr(hinfo(o).GroupHierarchy.Groups(n).Groups(3),'cellID');
                        cind = find(strcmp(cname, {thisRetina.cells(:).Name}));
                        if ~isempty(cind)
                            thisCell = thisRetina.cells(cind);
                        else
                            cind = length(thisRetina.cells) + 1;
                            emp = cell(1,1);
                            thisCell = struct('Name',cname,...
                                'online_label',get_attr(hinfo(o).GroupHierarchy.Groups(n),'label'),...
                                'location', emp);
                        end
                        
                        emp = cell(numel(hinfo(o).GroupHierarchy.Groups(n).Groups(2).Groups),1);
                        epochs = cat(1,epochs,struct('parameters',emp,'data_link',emp,'units',emp, 'sample_rate',emp,'start_time',emp,'duration',emp,'group',emp,'block',emp,'protocol',emp,'retina',emp,'cell',emp));
                        for m=1:numel(hinfo(o).GroupHierarchy.Groups(n).Groups(2).Groups)
                            epoch_count = epoch_count + 1;
                            epochs(epoch_count).retina = rind;
                            epochs(epoch_count).cell = cind;
                            epoch = hinfo(o).GroupHierarchy.Groups(n).Groups(2).Groups(m);
                            protocol = split(get_attr(epoch, 'protocolID'),'.');
                            epochs(epoch_count).protocol = protocol{end};
                            epochs(epoch_count).start_time = datetime(uint64(get_attr(epoch,'startTimeDotNetDateTimeOffsetUTCTicks')),'convertfrom','.net','timezone',num2str(get_attr(epoch,'startTimeUTCOffsetHours')));
                            epochs(epoch_count).duration = get_attr(epoch,'durationSeconds');
                            
                            epochs(epoch_count).parameters = struct(...
                                'Name',{epoch.Groups(1).Attributes(:).Shortname},...
                                'Value',arrayfun(@(x) get_attr(epoch.Groups(1), x.Shortname), epoch.Groups(1).Attributes,'uniformoutput',false),...
                                'Type',arrayfun(@(x) x.Datatype.Class, epoch.Groups(1).Attributes, 'uniformoutput',false)...
                                );
                            try
                                epochs(epoch_count).sample_rate = get_attr(epoch.Groups(2).Groups(1),'sampleRate');
                            catch ME
                                if ~strcmp(ME.identifier, 'MATLAB:imagesci:hdf5lib:libraryError')
                                    rethrow(ME);
                                end
                                epochs(epoch_count).sample_rate = epochs(epoch_count).parameters(strcmp({epochs(epoch_count).parameters(:).Name}, 'sampleRate')).Value;
                            end
                            data_links = arrayfun(@(x) sprintf('%s/data', x.Name), epoch.Groups(2).Groups,'uniformoutput',false);
                            
                            epochs(epoch_count).data_link = data_links(contains(data_links, 'Amplifier'));
                            epochs(epoch_count).units = cellfun(...
                                @(x) deblank(h5read(files{o}, x, 1, 1).unit'),...
                                epochs(epoch_count).data_link, 'uniformoutput',false);
                        end
                        
                        thisRetina.cells(cind) = thisCell;
                        retinas(rind) = thisRetina;
                    end
                end
                
                recording_datetime = min(cellfun(@(x,y) datetime(uint64(x),'ConvertFrom','.net','timezone',num2str(y)),...
                    recording_time(:,1), recording_time(:,2)));
                recording_time = datestr(recording_datetime,'HH:MM:SS');
                recording_date = datestr(recording_datetime,'YYYY-mm-DD');
                
                [epochs(:).start_time] = subsref(cellfun(@(x) milliseconds(x - recording_datetime), {epochs(:).start_time},'uniformoutput',false), substruct('{}',{':'}));
            end
        end
        
        function [keys, params, retina_cell] = processCellData(cellData, epochs, epoch_groups)
            
            if cellData.savedDataSets.Count < 1
                keys = {};
                params = {};
                retina_cell = {};
                return%we will not insert this cell
            end
            retina_cell = [];
            keys.datasets = struct('dataset_name', repmat(cellData.savedDataSets.keys()',1,2));
            
            ss = substruct('{}',{':'});
            
            emp = cell(0,1);
            keys.epochs = struct('epoch_number', emp,'start_time',emp,'duration',emp,'sample_rate',emp,'protocol_name',emp); %TODO: fill in...
            emp = cell(0,2);
            keys.channels = struct('epoch_number', emp, 'channel', emp, 'amp_mode', emp, 'recording_mode', emp, 'amp_hold', emp, 'data_link', emp);
            keys.spikes = struct('epoch_number', emp, 'channel', emp, 'count', emp, 'spikes', emp);
            keys.datasetEpochs = struct(...
                'dataset_name',emp,...
                'epoch_number', emp,...
                'channel',emp);
            
            error(); %this is a big mess
            if isempty(epoch_groups)
                paramNames = {'ampHoldSignal', 'ampMode', 'amp2HoldSignal', 'amp2Mode'}'; %TODO: is this right for symphony 1 second channel?
            else
                paramNames = {'chan1Hold', 'chan1Mode','chan2Hold','chan2Mode'}';
            end
            paramTypes = {'H5T_FLOAT', 'H5T_STRING', 'H5T_FLOAT','H5T_STRING'}';
            nParams = length(paramNames);
            emp = cell(nParams, 0);
            params = struct('Name',emp,'Value',emp,'Type',emp);
            
            v = cellData.savedDataSets.values();
            for m = 1:cellData.savedDataSets.Count
                nEpochs = numel(v{m});
                % nChannels = numel(cellData.epochs(v{m}(1)).dataLinks.keys());
                % datasetEpochs = zeros(nEpochs,nChannels);
                
                % datasetChannels = zeros(1,nChannels);
                emp = cell(nEpochs,1);
                epochsDataset = struct('epoch_number', emp,'start_time',emp,'duration',emp,'sample_rate',emp,'protocol_name',emp);
                emp = cell(nEpochs, 2);
                c = repmat({1,2}, nEpochs, 1);
                datasetChannels = struct('epoch_number', emp, 'channel', c, 'amp_mode', emp, 'recording_mode', emp, 'amp_hold', emp, 'data_link', emp);
                datasetSpikes = struct('epoch_number', emp, 'channel', c, 'count', emp, 'spikes', emp);
                
                datasetEpochs = struct(...
                    'dataset_name',repmat({keys.datasets(m).dataset_name}, nEpochs, 2),...
                    'epoch_number', emp,...
                    'channel',c);
                
                emp = cell(size(params,1),nEpochs);
                datasetParams = struct('Name',emp,'Value',emp,'Type',emp);
                
                [datasetParams(:).Name] = subsref(repmat(paramNames,1,nEpochs), ss);
                [datasetParams(:).Type] =  subsref(repmat(paramTypes,1,nEpochs), ss);
                [datasetParams(:).Value] = deal(nan);
                
                for l = 1:nEpochs
                    epoch = cellData.epochs(v{m}(l));
                    channel1= epoch.dataLinks('Amplifier_Ch1');
                    
                    epoch_ind = find(strcmp(arrayfun(@(e) e.data_link{1}, epochs, 'uniformoutput',false), channel1));
                    [datasetEpochs(l,:).epoch_number] = deal(epoch_ind); %this key is done
                    
                    if ismember(epoch_ind, [keys.epochs(:).epoch_number])
                        continue %we already parsed the epoch and channel data
                    end
                    epochsDataset(l).epoch_number = epoch_ind;
                    
                    if isempty(retina_cell) && ~isempty(epoch_groups) && ~isempty(epochs(epoch_ind).group)
                        retina_cell = [epoch_groups(epochs(epoch_ind).group).retina, epoch_groups(epochs(epoch_ind).group).cell];
                    end
                    %store the parameters and expand the existing structure
                    %with nans to incorporate new values
                    if isempty(retina_cell)
                        parameters = epochs(epoch_ind).parameters;
                    else
                        parameters = cat(1,epochs(epoch_ind).parameters, epoch_groups(epochs(epoch_ind).group).blocks(epochs(epoch_ind).block).parameters);
                    end
                    newParams = cellfun(@(x) ~any(strcmp(x,paramNames)),{parameters(:).Name});
                    if any(newParams)
                        
                        paramNames = cat(1,paramNames,{parameters(newParams).Name}');
                        paramTypes = cat(1,paramTypes,{parameters(newParams).Type}');
                        [datasetParams(nParams+1 :nParams+nnz(newParams),:).Value] = deal(nan);
                        [datasetParams(nParams+1 :nParams+nnz(newParams),:).Type] = subsref(repmat({parameters(newParams).Type}',1,nEpochs),ss);
                        [datasetParams(nParams+1 :nParams+nnz(newParams),:).Name] = subsref(repmat({parameters(newParams).Name}',1,nEpochs),ss);
                        
                        nParams = length(paramNames);
                    end
                    [datasetParams(cellfun(@(x) find(strcmp(x,paramNames)),{parameters(:).Name}),l).Value] = deal(parameters(:).Value);
                    
                    
                    %prepare the channel 1 key
                    datasetChannels(l,1).data_link = channel1;
                    datasetChannels(l,1).amp_hold = datasetParams(1,l).Value;
                    datasetChannels(l,1).recording_mode = datasetParams(2,l).Value;
                    if strcmp(epochs(epoch_ind).units{1},'pA')
                        datasetChannels(l,1).amp_mode = 'Vclamp';
                    elseif strcmp(epochs(epoch_ind).units{1},'mV')
                        datasetChannels(l,1).amp_mode = 'Iclamp';
                    end
                    if strcmp(datasetChannels(l,1).recording_mode,'Cell attached') || strcmp(datasetChannels(l,1), 'Iclamp')
                        datasetSpikes(l,1).spikes = uint32(epoch.get('spikes_ch1'));
                        if isnan(datasetSpikes(l,1).spikes)
                            error('Missing spikes in channel 1!');
                        end
                        datasetSpikes(l,1).count = numel(datasetSpikes(l,1).spikes);
                    end
                    
                    
                    %prepare the channel 2 key
                    nChannels = nnz(contains(epoch.dataLinks.keys(),'Amplifier'));
                    if nChannels== 2
                        datasetChannels(l,2).data_link = epoch.dataLinks('Amplifier_Ch2');
                        datasetChannels(l,2).amp_hold = datasetParams(3,l).Value;
                        datasetChannels(l,2).recording_mode = datasetParams(4,l).Value;
                        if strcmp(epochs(epoch_ind).units{2},'pA')
                            datasetChannels(l,2).amp_mode = 'Vclamp';
                        elseif strcmp(epochs(epoch_ind).units{2},'mV')
                            datasetChannels(l,2).amp_mode = 'Iclamp';
                        end
                        if strcmp(datasetChannels(l,2).recording_mode,'Cell attached') || strcmp(datasetChannels(l,2), 'Iclamp')
                            datasetSpikes(l,2).spikes = uint32(epoch.get('spikes_ch1'));
                            if isnan(datasetSpikes(l,2).spikes)
                                error('Missing spikes in channel 2!');
                            end
                            datasetSpikes(l,2).count = numel(datasetSpikes(l,2).spikes);
                        end
                    elseif nChannels > 2
                        error('More than 2 channels in cell data file');
                    end
                    
                    [datasetChannels(l,:).epoch_number] = deal(epoch_ind);
                    [datasetSpikes(l,:).epoch_number] = deal(epoch_ind);
                    
                    %prepare the epoch key
                    if isempty(retina_cell)
                        epochsDataset(l).protocol_name = epochs(epoch_ind).protocol;
                    else
                        epochsDataset(l).protocol_name = epoch_groups(epochs(epoch_ind).group).blocks(epochs(epoch_ind).block).protocol;
                    end
                    
                    epochsDataset(l).start_time = epochs(epoch_ind).start_time;
                    epochsDataset(l).duration = epochs(epoch_ind).duration;
                    epochsDataset(l).sample_rate = epochs(epoch_ind).sample_rate;
                end
                
                %remove null epochs from epochsDataset, channels...
                %don't think we want this here %%%%flatten epochsDataset, channels, datasetEpochs and remove null channels
                
                %concatenate keys
                newEpochs = arrayfun(@(x) ~isempty(x.epoch_number), epochsDataset);
                
                keys.epochs = vertcat(keys.epochs, epochsDataset(newEpochs));
                keys.channels = vertcat(keys.channels, datasetChannels(newEpochs,:));
                keys.spikes = vertcat(keys.spikes, datasetSpikes(newEpochs,:));
                keys.datasetEpochs = vertcat(keys.datasetEpochs, datasetEpochs);
                nParamsO = size(params,1) + 1;
                nEpochsO = size(params,2);
                
                
                [params(nParamsO:nParams,:).Value] = deal(nan);
                [params(nParamsO:nParams,:).Type] = subsref(repmat({datasetParams(nParamsO:end,1).Type},1,nEpochsO),ss);
                [params(nParamsO:nParams,:).Name] = subsref(repmat({datasetParams(nParamsO:end,1).Name},1,nEpochsO),ss);
                params = horzcat(params, datasetParams(:, newEpochs));
                
            end
            
        end
    end
end