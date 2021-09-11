%{
#A handle to a Symphony raw data file
filename: varchar(64)
---
-> sl.Rig
experiment_start_time: datetime
experiment_end_time: datetime
symphony_major_version: tinyint unsigned
symphony_minor_version: tinyint unsigned
symphony_patch_version: tinyint unsigned
symphony_revision_version: tinyint unsigned
#datafile : attach@raw #copy of the raw data file stored by dj, not doing this for now
%}
classdef Symphony < dj.Manual
    properties (Constant)
        RAW_DATA_FOLDER = getenv('RAW_DATA_FOLDER')
    end
    
    methods
        
        function insert(self, key)
            if isa(key,'char')
                filename = {key};
%                 key = struct('filename', filename);
            elseif isa(key,'struct') && isfield(key,'filename')
                filename = unique({key(:).filename});
            else
                error('Key must be the name of a file or a struct that contains `filename` as a field.');
            end
            assert(numel(filename) == 1,'Inserting multiple raw data files at a time is not yet supported.');
            filename = cell2mat(filename);
            
            key = self.loadHDF5(filename);
            
            transacted = false;
            if self.schema.conn.inTransaction
                transacted = true;
            else
                self.schema.conn.startTransaction;
            end
            try
                insert@dj.Manual(self, rmfield(key,{'epoch_groups','epoch_blocks','epochs','epoch_channels','channels', 'sources', 'retinas', 'cells'}));
                sln_symphony.SymphonySource().insert(key.sources)

                [key.retinas(:).animal_id] = deal(1); %placeholder!
                sln_symphony.SymphonyRetina().insert(key.retinas);
                sln_symphony.SymphonyCell().insert(key.cells);
                sln_symphony.SymphonyEpochGroup().insert(key.epoch_groups);
                sln_symphony.SymphonyEpochBlock().insert(rmfield(key.epoch_blocks,'protocol_params'));
                sln_symphony.SymphonyEpoch().insert(rmfield(key.epochs,'epoch_params'));
                sln_symphony.SymphonyChannel().insert(rmfield(key.channels,'units'));
                sln_symphony.SymphonyEpochChannel().insert(key.epoch_channels);
                
            catch ME
                if ~transacted
                    self.schema.conn.cancelTransaction;
                end
                rethrow(ME);
            end
            if ~transacted
                self.schema.conn.commitTransaction;
            end
            
        end
        
        function key = loadHDF5(self,filename)
            %% parse the input and ensure the file exists
            key.filename = filename;
            if nargin<2
                filename = self.fetch1('filename');
            else
                assert(isa(filename,'char') && size(filename,1) == 1, 'Loading multiple hdf5 files is not yet supported');
            end
            
            fpath = fullfile(self.RAW_DATA_FOLDER,sprintf('%s.h5', filename));
            assert(exist(fpath,'file')==2, 'Raw data file not found in local raw data folder!')
            
            %% determine the version of the file
            try
                version = h5readatt(fpath,'/','version');
            catch ME
                if strcmp(ME.identifier, 'MATLAB:imagesci:hdf5lib:fileOpenErr') || strcmp(ME.identifier, 'MATLAB:imagesci:hdf5lib:libraryError')
                    version = 1; %could still be okay
                else
                    rethrow(ME);
                end
            end
            
            if version == 1
                hinfo = hdf5info(fpath,'ReadAttributes',false); %#ok<HDFI>
                parseSymphony1();
            else
                hinfo = h5info(fpath);
                parseSymphony2();
            end

            %make key.sources
            key.sources = struct('source_id',num2cell(1:(numel(key.cells) + numel(key.retinas))));
            [key.sources(:).filename] = deal(key.filename);
            [key.retinas(:).filename] = deal(key.filename);
            [key.cells(:).filename] = deal(key.filename);
            [key.epoch_groups(:).filename] = deal(key.filename);
            [key.epoch_blocks(:).filename] = deal(key.filename);
            [key.epochs(:).filename] = deal(key.filename);
            [key.channels(:).filename] = deal(key.filename);
            [key.epoch_channels(:).filename] = deal(key.filename);
            
            
            %% parse symphony 2 files
            function parseSymphony2()
                key.rig_name = key.filename(end);
                emp = cell(1);
                key.symphony_major_version = 2;
                fullVersion = cellfun(@str2num,strsplit(parseAttr(hinfo.Attributes,'symphonyVersion'),'.'));
                key.symphony_minor_version = fullVersion(2);
                key.symphony_patch_version = fullVersion(3);
                key.symphony_revision_version = fullVersion(4);
                
                % the experiment is stored under hinfo.Groups(1)
                % key.experiment_uuid = parseAttr(hinfo.Groups(1).Attributes,'uuid');
                [key.experiment_start_time,key.experiment_end_time,experiment_start_time] = parseDOTNETts(hinfo.Groups(1).Attributes);
                experiment_start_day = dateshift(experiment_start_time,'start','day');
                %experiment properties are under hinfo.Groups(1).Groups(3)
                experimenter = parseAttr(hinfo.Groups(1).Groups(3).Attributes,'experimenter');
                
                %devices are under hinfo.Groups(1).Groups(1)
                
                %epochGroups are under hinfo.Groups(1).Groups(2).Groups(:)
                nEpochGroups = numel(hinfo.Groups(1).Groups(2).Groups);
                emp = cell(1,nEpochGroups);
                
                %TODO: fold into existing??
                key.epoch_groups = struct('epoch_group_id',emp,...
                    'source_id',emp,...
                    'epoch_group_start_time',emp,'epoch_group_end_time',emp,'epoch_group_label',emp);
                
                emp = cell(0);
                % key.sources = struct('source_id',emp);
                key.retinas = struct('source_id',emp,...
                    'animal_id',emp,'side',emp,'orientation',emp,'experimenter',emp);
                key.cells = struct('source_id',emp,...
                    'cell_name',emp,'cell_number',emp,'online_label',emp,'x',emp,'y',emp,...
                    'retina_id',emp);
                
                key.epoch_blocks = struct('epoch_block_id',emp,...
                    'protocol_name',emp,'protocol_params',emp,...
                    'epoch_block_start_time',emp,'epoch_block_end_time',emp,...
                    'epoch_group_id',emp,...
                    'source_id',emp);
                
                key.epochs = struct('epoch_id', emp,...
                    'epoch_start_time',emp,'epoch_duration', emp,...
                    'epoch_params',emp,...
                    'epoch_block_id',emp,'epoch_group_id',emp,...
                    'source_id',emp);
                
                key.channels = struct('channel_name',emp,...
                    'sample_rate',emp,'units',emp,...
                    'epoch_block_id',emp,'epoch_group_id',emp,...
                    'source_id',emp);
                
                key.epoch_channels = struct('channel_name',emp,...
                    'raw_data',emp,...
                    'epoch_id',emp,'epoch_block_id',emp,'epoch_group_id',emp,...
                    'source_id',emp);

                sources = containers.Map();
                
                for n = 1:nEpochGroups
                    % key.epoch_groups(n).epoch_group_uuid = ...
                    %     parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Attributes,'uuid');
                    key.epoch_groups(n).epoch_group_id = n;
                    [key.epoch_groups(n).epoch_group_start_time,key.epoch_groups(n).epoch_group_end_time] = parseDOTNETts(...
                        hinfo.Groups(1).Groups(2).Groups(n).Attributes);
                    key.epoch_groups(n).epoch_group_label = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Attributes,'label');
                    
                    %source is either under eg.Groups(4) or eg.Links(2)
                    if numel(hinfo.Groups(1).Groups(2).Groups(n).Groups) < 4
                        source_cell = strsplit(cell2mat(hinfo.Groups(1).Groups(2).Groups(n).Links(2).Value),'/source-');
                        source_id = sources(source_cell{end});
                        key.epoch_groups(n).source_id = source_id;
                    else
                        source_id = sources.length + 1;
                        sources(parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Attributes,'uuid')) = source_id;
                        key.epoch_groups(n).source_id = source_id;
                        
                        %add source data, since this is a new source
                        % key.sources(end+1).source_id = source_id;
                        
                        %symphony doesn't save the source type... so we'll
                        %extract it
                        sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(3).Attributes);
                        if isfield(sub_key,'type') %this is a cell
                            key.cells(end+1).source_id = source_id;
                            key.cells(end) = parseCell(key.cells(end), sub_key);
                            key.cells(end).cell_name = str2double(...
                                parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Attributes,'label')...
                                );
                            
                            %we always have a new retina
                            retina_id = sources.length + 1;
                            sources(parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Attributes,'uuid')) = retina_id;
                            key.cells(end).retina_id = retina_id;
                            % key.sources(end+1).source_id = retina_id;
                            key.retinas(end+1).source_id = retina_id;
                            
                            sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(2).Attributes);
                            key.retinas(end).side = sub_key.eye;
                            key.retinas(end).orientation = sub_key.orientation;
                            if isfield(sub_key,'djid')
                                key.retinas(end).animal_id = sub_key.djid;
                            else
                                key.retinas(end).animal_id = sub_key.genotype; %the best we can do...
                            end
                            if isfield(sub_key,'experimenter')
                                key.retinas(end).experimenter = sub_key.experimenter;
                            else
                                key.retinas(end).experimenter = experimenter; %might be null
                            end
                            
                            %now check the retina's children
                            
                            nCells = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups);
                            for m=1:nCells
                                cell_id = sources.length + 1;
                                sources(parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Attributes,'uuid')) = cell_id;
                                % key.sources(end+1).source_id = cell_id;
                                key.cells(end+1).source_id = cell_id;
                                
                                sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Groups(2).Attributes);
                                key.cells(end) = parseCell(key.cells(end), sub_key);
                                key.cells(end).cell_name = str2double(...
                                    parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Attributes,'label')...
                                    );
                                
                                key.cells(end).retina_id = retina_id;
                            end
                        else %this is a retina... maybe an imaging exp?
                            error('attempted to add an epoch group to a retina! should be allowed, but need to parse this');
                        end
                    end
                    nBlocks = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups);
                    emp = cell(1,nBlocks);
                    epoch_blocks = struct('epoch_block_id',emp,...
                        'protocol_name',emp,'protocol_params',emp,...
                        'epoch_block_start_time',emp,'epoch_block_end_time',emp,...
                        'epoch_group_id',emp);
                    [epoch_blocks(:).epoch_group_id] = deal(n);
                    [epoch_blocks(:).source_id] = deal(source_id);
                    
                    for m = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups):-1:1
                        if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups)
                            % no recorded epochs for this block
                            epoch_blocks(m) = []; %TODO: is this what we ought to do??
                            continue;
                        end
                        
                        % epoch_blocks(m).epoch_block_uuid = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Attributes,'uuid');
                        epoch_blocks(m).epoch_block_id = m; 
                        [epoch_blocks(m).epoch_block_start_time,epoch_blocks(m).epoch_block_end_time] = parseDOTNETts(...
                            hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Attributes);
                        protocol_str = strsplit(parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Attributes,'protocolID'),'.');
                        epoch_blocks(m).protocol_name = protocol_str{end};
                        
                        %the protocol parameters are under Groups(2)
                        epoch_blocks(m).protocol_params = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(2).Attributes);
                        %the epochs are under Groups(2)
                        nEpochs = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups);
                        emp = cell(1,nEpochs);
                        epochs = struct('epoch_id', emp,...
                            'epoch_start_time',emp,'epoch_duration', emp,...
                            'epoch_params',emp);
                        [epochs(:).epoch_block_id] = deal(m);
                        [epochs(:).epoch_group_id] = deal(n);
                        [epochs(:).source_id] = deal(source_id);
                        
                        nChans = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(1).Groups(3).Groups);
                        emp = cell(1,nChans);
                        channels = struct('channel_name',emp,...
                            'sample_rate',emp,'units',emp);
                        [channels(:).epoch_block_id] = deal(m);
                        [channels(:).epoch_group_id] = deal(n);
                        [channels(:).source_id] = deal(source_id);

                        emp = cell(nEpochs,nChans);
                        epoch_channels = struct('channel_name',emp,...
                            'sample_rate',emp,'sample_rate_units',emp,...
                            'units',emp,...
                            'raw_data',emp,...
                            'epoch_id',emp);
                        [epoch_channels(:).epoch_block_id] = deal(m);
                        [epoch_channels(:).epoch_group_id] = deal(n);
                        [epoch_channels(:).source_id] = deal(source_id);
                        
                        
                        for el = 1:nEpochs
                            % epochs(el).epoch_uuid = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Attributes,'uuid');
                            epochs(el).epoch_id = el;
                            [epochs(el).epoch_start_time, epochs(el).epoch_duration] = parseDOTNETms(...
                            hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(1).Attributes,...
                            experiment_start_day);
                            epochs(el).epoch_params = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(2).Attributes);
                            
                            for k=1:nChans
                                epoch_channels(el,k).sample_rate = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(3).Groups(1).Attributes,'sampleRate');
                                epoch_channels(el,k).sample_rate_units = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(3).Groups(1).Attributes,'sampleRateUnits');
                                channel_str = strsplit(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(3).Groups(1).Name,'/');
                                channel_str = strsplit(channel_str{end},'-');
                                epoch_channels(el,k).channel_name = channel_str{1};
                                epoch_channels(el,k).epoch_id = el;
                                
                                raw_data = h5read(fpath,...
                                    horzcat(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(3).Groups(1).Name,'/data')...
                                    );
                                epoch_channels(el,k).raw_data = raw_data.quantity;
                                if isfield(raw_data,'units')
                                    epoch_channels(el,k).units = deblank(raw_data.units(:,1)');
                                else
                                    epoch_channels(el,k).units = deblank(raw_data.units(:,1)');
                                end
                            end
                        end
                        for k=1:nChans
                            channels(k) = rmfield(epoch_channels(end,k),{'raw_data','epoch_id','sample_rate_units'});
                            assert(all(strcmp({epoch_channels(:,k).channel_name}, channels(k).channel_name)),'Mis-matching channel names in epoch block!');
                            assert(all(strcmp({epoch_channels(:,k).sample_rate_units}, 'Hz')),'Sample rate not in Hz!');
                            assert(all(strcmp({epoch_channels(:,k).units}, channels(k).units)),'Multiple channel units in epoch block!');
                            assert(all([epoch_channels(:,k).sample_rate] == channels(k).sample_rate),'Multiple sample rates in epoch block!');
                        
                        end
                        
                        key.epochs = cat(2,key.epochs, epochs);
                        key.epoch_channels = cat(2,key.epoch_channels,rmfield(epoch_channels(:)',{'sample_rate','sample_rate_units','units'}));
                        key.channels = cat(2,key.channels,channels);
                    end
                    key.epoch_blocks = cat(2,key.epoch_blocks, epoch_blocks);
                end

            end
            
            
            
            %% parse symphony 1 files
            function parseSymphony1()
                error('symphony1 file detected');
            end
            
            
            %% helper functions
            function attr = parseAttr(attrs,attr_name)
                attr = attrs(strcmp({attrs(:).Name},attr_name)).Value;
            end
            
            function attrs_clean = parseAttrs(attrs)
                t = {attrs(:).Name;attrs(:).Value};
                attrs_clean = struct(t{:});
            end
            
            function s = parseCell(s,t)
                s.cell_number = t.number;
                if isempty(t.confirmedType)
                    s.online_label = t.type;
                else
                    s.online_label = t.confirmedType;
                end
                s.x = t.location(1);
                s.y = t.location(2);
            end
            
            function [start_str,end_str,start_dt,end_dt] = parseDOTNETts(attrs)
                
                start_dt = datetime(uint64(parseAttr(attrs,'startTimeDotNetDateTimeOffsetTicks')),...
                    'convertfrom','.net','timezone',...
                    num2str(parseAttr(attrs,'startTimeDotNetDateTimeOffsetOffsetHours')));
                end_dt = datetime(uint64(parseAttr(attrs,'endTimeDotNetDateTimeOffsetTicks')),...
                    'convertfrom','.net','timezone',...
                    num2str(parseAttr(attrs,'endTimeDotNetDateTimeOffsetOffsetHours')));
                
                start_str = datestr(start_dt,'YYYY-mm-DD HH:MM:SS');
                end_str = datestr(end_dt,'YYYY-mm-DD HH:MM:SS');
%                 date = datestr(dt,'YYYY-mm-DD');
%                 time = datestr(dt,'HH:MM:SS');
            end
            
            function [start_time_ms,duration] = parseDOTNETms(attrs, experiment_start_day)
                
                start_dt = datetime(uint64(parseAttr(attrs,'startTimeDotNetDateTimeOffsetTicks')),...
                    'convertfrom','.net','timezone',...
                    num2str(parseAttr(attrs,'startTimeDotNetDateTimeOffsetOffsetHours')));
                end_dt = datetime(uint64(parseAttr(attrs,'endTimeDotNetDateTimeOffsetTicks')),...
                    'convertfrom','.net','timezone',...
                    num2str(parseAttr(attrs,'endTimeDotNetDateTimeOffsetOffsetHours')));
                
                start_time_ms = milliseconds(start_dt - experiment_start_day);
                duration = milliseconds(end_dt - start_dt);
            end
        end
    end
    
    
end