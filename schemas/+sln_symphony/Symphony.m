%{
#A handle to a Symphony raw data file
filename: varchar(64)
---
experiment_id: uuid #TODO: only 1 experiment per file??
start_time: datetime
end_time: datetime
symphony_major_version: tinyint unsigned
symphony_minor_version: tinyint unsigned
symphony_patch_version: tinyint unsigned
symphony_revision_version: tinyint unsigned
#datafile : attach@raw_data_master #copy of the raw data file stored by dj, not doing this for now
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
            %the rig should be the last letter on the
            rig_name = upper(filename(end));
            %     assert(ismember(rig_name, {'A','B'}), 'Filename must end in the name of the rig on which it was recorded.');
            
            key = self.loadHDF5(filename, key);
            
            insert@dj.Manual(self, key);
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
                parseSymphony1(hdf5info(fpath,'ReadAttributes',false)); %#ok<HDFI>
            else
                parseSymphony2(h5info(fpath));
            end
            
            %% parse symphony 2 files
            function parseSymphony2(hinfo)
                emp = cell(1);
                key.symphony_major_version = 2;
                fullVersion = cellfun(@str2num,strsplit(parseAttr(hinfo.Attributes,'symphonyVersion'),'.'));
                key.symphony_minor_version = fullVersion(2);
                key.symphony_patch_version = fullVersion(3);
                key.symphony_revision_version = fullVersion(4);
                
                % the experiment is stored under hinfo.Groups(1)
                key.experiment_id = parseAttr(hinfo.Groups(1).Attributes,'uuid');
                [key.start_time,key.end_time] = parseDOTNETts(hinfo.Groups(1).Attributes);
                
                %experiment properties are under hinfo.Groups(1).Groups(3)
                experimenter = parseAttr(hinfo.Groups(1).Groups(3).Attributes,'experimenter');
                
                %devices are under hinfo.Groups(1).Groups(1)
                
                %epochGroups are under hinfo.Groups(1).Groups(2).Groups(:)
                nEpochGroups = numel(hinfo.Groups(1).Groups(2).Groups);
                emp = cell(nEpochGroups,1);
                
                %TODO: fold into existing??
                key.epoch_groups = struct('epoch_group_uuid',emp,...
                    'source_uuid',emp,...
                    'start_time',emp,'end_time',emp,'label',emp);
                
                emp = cell(0);
                key.sources = struct('source_uuid',emp);
                key.retinas = struct('source_uuid',emp,'animal_id',emp,'side',emp,'orientation',emp);
                key.cells = struct('source_uuid',emp,'cell_number',emp,'retina_uuid',emp,'online_label',emp,'x',emp,'y',emp);
                
                
                for n = 1:nEpochGroups
                    key.epoch_groups(n).epoch_group_uuid = ...
                        parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Attributes,'uuid');
                    [key.epoch_groups(n).start_time,key.epoch_groups(n).end_time] = parseDOTNETts(...
                        hinfo.Groups(1).Groups(2).Groups(n).Attributes);
                    key.epoch_groups(n).label = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Attributes,'label');
                    
                    %source is either under eg.Groups(4) or eg.Links(2)
                    if numel(hinfo.Groups(1).Groups(2).Groups(n).Groups) < 4
                        source_cell = strsplit(cell2mat(hinfo.Groups(1).Groups(2).Groups(n).Links(2).Value),'/source-');
                        key.epoch_groups(n).source_uuid = source_cell{2};
                    else
                        source_uuid = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Attributes,'uuid');
                        key.epoch_groups(n).source_uuid = source_uuid;
                        
                        %add source data, since this is a new source
                        key.sources(end+1).source_uuid = source_uuid;
                        
                        %symphony doesn't save the source type... so we'll
                        %extract it
                        sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(3).Attributes);
                        if isfield(sub_key,'type') %this is a cell
                            key.cells(end+1).source_uuid = source_uuid;
                            key.cells(end) = parseCell(key.cells(end), sub_key);
                            
                            retina_uuid = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Attributes,'uuid');
                            key.cells(end).retina_uuid = retina_uuid;
                            
                            %we always have a new retina
                            key.sources(end+1).source_uuid = retina_uuid;
                            key.retinas(end+1).source_uuid = retina_uuid;
                            
                            sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(2).Attributes);
                            key.retinas(end).side = sub_key.eye;
                            key.retinas(end).orientation = sub_key.orientation;
                            if isfield(sub_key,'djid')
                                key.retinas(end).animal_id = sub_key.djid;
                            else
                                key.retinas(end).animal_id = sub_key.genotype; %the best we can do
                            end
                            
                            %now check the retina's children
                            
                            nCells = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups);
                            for m=1:nCells
                                cell_uuid = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Attributes,'uuid');
                                key.sources(end+1).source_uuid = cell_uuid;
                                key.cells(end+1).source_uuid = cell_uuid;
                                
                                sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Groups(2).Attributes);
                                key.cells(end) = parseCell(key.cells(end), sub_key);
                                key.cells(end).retina_uuid = retina_uuid;
                            end
                        else %this is a retina... maybe an imaging exp?
                            error('added an epoch group to a retina! need to parse this');
                        end
                        
                        %add source data...
                    end
                end
            end
            
            
            
            %% parse symphony 1 files
            function parseSymphony1(hinfo)
                
                fprintf('.');
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
        end
    end
    
    
end