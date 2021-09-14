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
                insert@dj.Manual(self, rmfield(key,...
                    {'epoch_groups','epoch_blocks','epochs','epoch_channels',...
                    'channels', 'sources', 'retinas','cells',...
                    'notes','retina_notes','cell_notes',...
                    'epoch_group_notes','epoch_block_notes','epoch_notes'}...
                    ));
                sln_symphony.SymphonySource().insert(key.sources)
                
                
                [key.retinas(:).animal_id] = deal(1); %placeholder!
                sln_symphony.SymphonyRetina().insert(key.retinas);
                
                sln_symphony.SymphonyCell().insert(key.cells);
                
                sln_symphony.SymphonyEpochGroup().insert(key.epoch_groups);
                
                sln_symphony.SymphonyEpochBlock().insert(rmfield(key.epoch_blocks,'protocol_params'));
                
                sln_symphony.SymphonyEpoch().insert(rmfield(key.epochs,'epoch_params'));
                
                sln_symphony.SymphonyChannel().insert(rmfield(key.channels,'units'));
                sln_symphony.SymphonyEpochChannel().insert(key.epoch_channels);
                
                
                if ~isempty(key.notes)
                    sln_symphony.SymphonyNote().insert(key.notes);
                end
                if ~isempty(key.retina_notes)
                    sln_symphony.SymphonyRetinaNote().insert(key.retina_notes);
                end
                if ~isempty(key.cell_notes)
                    sln_symphony.SymphonyCellNote().insert(key.cell_notes);
                end
                if ~isempty(key.epoch_group_notes)
                    sln_symphony.SymphonyEpochGroupNote().insert(key.epoch_group_notes);
                end
                if ~isempty(key.epoch_block_notes)
                    sln_symphony.SymphonyEpochBlockNote().insert(key.epoch_block_notes);
                end
                if ~isempty(key.epoch_notes)
                    sln_symphony.SymphonyEpochNote().insert(key.epoch_notes);
                end
                
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
            % NOTE: this function is incredibly hard to read
            % the underlying issue is that hdf5 is an outmoded file format
            % also, MATLAB is not designed to parse tree structures quickly
            % thus we are sacrificing readability for speed
            
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
            
            %pull the notes out...
            
            key.retina_notes = [key.retinas(:).notes];
            key.cell_notes = [key.cells(:).notes];
            key.epoch_group_notes = [key.epoch_groups(:).notes];
            key.epoch_block_notes = [key.epoch_blocks(:).notes];
            key.epoch_notes = [key.epochs(:).notes];
            
            key.retinas = rmfield(key.retinas,'notes');
            key.cells = rmfield(key.cells,'notes');
            key.epoch_groups = rmfield(key.epoch_groups,'notes');
            key.epoch_blocks = rmfield(key.epoch_blocks,'notes');
            key.epochs = rmfield(key.epochs,'notes');
            
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
            
            
            if ~isempty(key.notes)
                [key.notes(:).filename] = deal(key.filename);
            end
            if ~isempty(key.retina_notes)
                [key.retina_notes(:).filename] = deal(key.filename);
            end
            if ~isempty(key.cell_notes)
                [key.cell_notes(:).filename] = deal(key.filename);
            end
            if ~isempty(key.epoch_group_notes)
                [key.epoch_group_notes(:).filename] = deal(key.filename);
            end
            if ~isempty(key.epoch_block_notes)
                [key.epoch_block_notes(:).filename] = deal(key.filename);
            end
            if ~isempty(key.epoch_notes)
                [key.epoch_notes(:).filename] = deal(key.filename);
            end
            
            %sort the ids so that they increment naturally
            sort_keys_by_start_time();
            
            %% parse symphony 2 files
            function parseSymphony2()
                key.rig_name = key.filename(end);
                emp = cell(1);
                key.symphony_major_version = 2;
                fullVersion = cellfun(@str2num,strsplit(parseAttr(hinfo.Attributes,'symphonyVersion'),'.'));
                key.symphony_minor_version = fullVersion(2);
                key.symphony_patch_version = fullVersion(3);
                key.symphony_revision_version = fullVersion(4);
                
                if isempty(hinfo.Groups.Datasets) || ~any(strcmp({hinfo.Groups.Datasets(:).Name},'notes'))
                    key.notes = [];
                else
                    note = h5read(fpath,[hinfo.Groups.Name '/notes']);
                    key.notes = struct('entry_time',parseNoteTime(note.time),'text',note.text,'note_index',...
                        num2cell(1:numel(note)));
                end
                
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
                    'epoch_group_start_time',emp,'epoch_group_end_time',emp,...
                    'epoch_group_label',emp,'notes',emp);
                
                emp = cell(0);
                % key.sources = struct('source_id',emp);
                key.retinas = struct('source_id',emp,...
                    'animal_id',emp,'side',emp,'orientation',emp,'experimenter',emp,...
                    'notes',emp);
                key.cells = struct('source_id',emp,...
                    'cell_name',emp,'cell_number',emp,'online_label',emp,'x',emp,'y',emp,...
                    'retina_id',emp,'notes',emp);
                
                key.epoch_blocks = struct('epoch_block_id',emp,...
                    'protocol_name',emp,'protocol_params',emp,...
                    'epoch_block_start_time',emp,'epoch_block_end_time',emp,...
                    'epoch_group_id',emp,...
                    'source_id',emp,'notes',emp);
                
                key.epochs = struct('epoch_id', emp,...
                    'epoch_start_time',emp,'epoch_duration', emp,...
                    'epoch_params',emp,...
                    'epoch_block_id',emp,'epoch_group_id',emp,...
                    'source_id',emp,'notes',emp);
                
                key.channels = struct('channel_name',emp,...
                    'sample_rate',emp,...
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
                    
                    if isempty(hinfo.Groups(1).Groups(2).Groups(n).Datasets) || ~any(strcmp({hinfo.Groups(1).Groups(2).Groups(n).Datasets(:).Name},'notes'))
                        key.epoch_groups(n).notes = [];
                    else
                        note = h5read(fpath,[hinfo.Groups(1).Groups(2).Groups(n).Name '/notes']);
                        key.epoch_groups(n).notes = struct(...
                            'epoch_group_id',n,...
                            'entry_time',parseNoteTime(note.time),'text',note.text,...
                            'note_index',num2cell(1:numel(note)));
                    end
                    
                    %source is either under eg.Groups(4) or eg.Links(2)
                    if numel(hinfo.Groups(1).Groups(2).Groups(n).Groups) < 4
                        %this source has already been populated
                        source_cell = strsplit(cell2mat(hinfo.Groups(1).Groups(2).Groups(n).Links(2).Value),'/source-');
                        if numel(source_cell)<2
                            %source uuid is not in the Name
                            source_id = sources(h5readatt(fpath,source_cell{1},'uuid'));
                        else
                            source_id = sources(source_cell{end});
                            key.epoch_groups(n).source_id = source_id;
                        end
                    else % a new source
                        source_id = sources.length + 1;
                        sources(parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Attributes,'uuid')) = source_id;
                        key.epoch_groups(n).source_id = source_id;
                        
                        %add source data, since this is a new source
                        % key.sources(end+1).source_id = source_id;
                        
                        %symphony doesn't save the source type... so we'll
                        %extract it
                        props = contains({hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(:).Name},'properties');
                        sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(props).Attributes);
                        if isfield(sub_key,'type') %this is a cell
                            key.cells(end+1).source_id = source_id;
                            key.cells(end) = parseCell(key.cells(end), sub_key);
                            key.cells(end).cell_name = str2double(...
                                parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Attributes,'label')...
                                );
                            
                            if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Datasets) || ~any(strcmp({hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Datasets(:).Name},'notes'))
                                key.cells(end).notes = [];
                            else
                                note = h5read(fpath,[hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Name '/notes']);
                                key.cells(end).notes = struct(...
                                    'source_id',source_id,...
                                    'entry_time',parseNoteTime(note.time),'text',note.text,...
                                    'note_index',num2cell(1:numel(note)));
                            end
                            
                            %we always have a new retina
                            retina_id = sources.length + 1;
                            sources(parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Attributes,'uuid')) = retina_id;
                            key.cells(end).retina_id = retina_id;
                            % key.sources(end+1).source_id = retina_id;
                            key.retinas(end+1).source_id = retina_id;
                            
                            if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Datasets) || ~any(strcmp({hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Datasets(:).Name},'notes'))
                                key.retinas(end).notes = [];
                            else
                                note = h5read(fpath,[hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Name '/notes']);
                                key.retinas(end).notes = struct(...
                                    'source_id',retina_id,...
                                    'entry_time',parseNoteTime(note.time),'text',note.text,...
                                    'note_index',num2cell(1:numel(note)));
                            end
                            
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
                                
                                if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Datasets) || ~any(strcmp({hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Datasets(:).Name},'notes'))
                                    key.cells(end).notes = [];
                                else
                                    note = h5read(fpath,[hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Name '/notes']);
                                    key.cells(end).notes = struct(...
                                        'source_id',cell_id,...
                                        'entry_time',parseNoteTime(note.time),'text',note.text,...
                                        'note_index',num2cell(1:numel(note)));
                                end
                                
                                sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Groups(2).Attributes);
                                key.cells(end) = parseCell(key.cells(end), sub_key);
                                key.cells(end).cell_name = str2double(...
                                    parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Attributes,'label')...
                                    );
                                
                                key.cells(end).retina_id = retina_id;
                            end
                        else %this is a retina... maybe an imaging exp?
                            %                             error('attempted to add an epoch group to a retina! should be allowed, but need to parse this');
                            %                             sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(props).Attributes);
                            key.retinas(end+1).source_id = source_id;
                            
                            if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Datasets) || ~any(strcmp({hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Datasets(:).Name},'notes'))
                                key.retinas(end).notes = [];
                            else
                                note = h5read(fpath,[hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Name '/notes']);
                                key.retinas(end).notes = struct(...
                                    'source_id',source_id,...
                                    'entry_time',parseNoteTime(note.time),'text',note.text,...
                                    'note_index',num2cell(1:numel(note)));
                            end
                            
                            key.retinas(end).side = sub_key.eye;
                            key.retinas(end).orientation = sub_key.orientation;
                            if isfield(sub_key,'djid')
                                key.retinas(end).animal_id = sub_key.djid;
                            elseif isfield(sub_key,'DataJointIdentifier') %TODO: TEMPORARY!
                                key.retinas(end).animal_id = sub_key.DataJointIdentifier;
                            else
                                key.retinas(end).animal_id = sub_key.genotype; %the best we can do...
                            end
                            if isfield(sub_key,'experimenter')
                                key.retinas(end).experimenter = sub_key.experimenter;
                            elseif isfield(sub_key,'recordingBy') && ~isempty(sub_key.recordingBy) %TODO: does this belong elsewhere too?
                                key.retinas(end).experimenter = experimenter; %might be null
                            end
                            
                            %now check the retina's children
                            
                            nCells = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups);
                            for m=1:nCells
                                error('epoch group on a retina, but also epoch group on cells')
%                                 cell_id = sources.length + 1;
%                                 sources(parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Attributes,'uuid')) = cell_id;
%                                 % key.sources(end+1).source_id = cell_id;
%                                 key.cells(end+1).source_id = cell_id;
%                                 
%                                 if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Datasets) || ~any(strcmp({hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Datasets(:).Name},'notes'))
%                                     key.cells(end).notes = [];
%                                 else
%                                     note = h5read(fpath,[hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Name '/notes']);
%                                     key.cells(end).notes = struct(...
%                                         'source_id',cell_id,...
%                                         'entry_time',parseNoteTime(note.time),'text',note.text,...
%                                         'note_index',num2cell(1:numel(note)));
%                                 end
%                                 
%                                 sub_key = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Groups(2).Attributes);
%                                 key.cells(end) = parseCell(key.cells(end), sub_key);
%                                 key.cells(end).cell_name = str2double(...
%                                     parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(4).Groups(2).Groups(4).Groups(m).Attributes,'label')...
%                                     );
%                                 
%                                 key.cells(end).retina_id = retina_id;
                            end
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
                    
                    mm = numel(key.epoch_blocks);
                    for m = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups):-1:1
                        if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups)
                            % no recorded epochs for this block
                            epoch_blocks(m) = []; %TODO: is this what we ought to do??
                            continue;
                        end
                        
                        if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Datasets) || ~any(strcmp({hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Datasets(:).Name},'notes'))
                            epoch_blocks(m).notes = [];
                        else
                            note = h5read(fpath,[hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Name '/notes']);
                            epoch_blocks(m).notes = struct(...
                                'epoch_group_id',n,'epoch_block_id',mm+m,...
                                'entry_time',parseNoteTime(note.time),'text',note.text,...
                                'note_index',num2cell(1:numel(note)));
                        end
                        
                        % epoch_blocks(m).epoch_block_uuid = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Attributes,'uuid');
                        epoch_blocks(m).epoch_block_id = mm+m;
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
                        [epochs(:).epoch_block_id] = deal(mm+m);
                        [epochs(:).epoch_group_id] = deal(n);
                        [epochs(:).source_id] = deal(source_id);
                        
                        nChans = numel(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(1).Groups(3).Groups);
                        emp = cell(1,nChans);
                        channels = struct('channel_name',emp,...
                            'sample_rate',emp);
                        [channels(:).epoch_block_id] = deal(mm+m);
                        [channels(:).epoch_group_id] = deal(n);
                        [channels(:).source_id] = deal(source_id);
                        
                        emp = cell(nEpochs,nChans);
                        epoch_channels = struct('channel_name',emp,...
                            'sample_rate',emp,'sample_rate_units',emp,...
                            'units',emp,...
                            'raw_data',emp,...
                            'epoch_id',emp);
                        [epoch_channels(:).epoch_block_id] = deal(mm+m);
                        [epoch_channels(:).epoch_group_id] = deal(n);
                        [epoch_channels(:).source_id] = deal(source_id);
                        
                        ell = numel(key.epochs);
                        for el = 1:nEpochs
                            % epochs(el).epoch_uuid = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Attributes,'uuid');
                            if isempty(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Datasets) || ~any(strcmp({hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Datasets(:).Name},'notes'))
                                epochs(el).notes = [];
                            else
                                note = h5read(fpath,[hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Name '/notes']);
                                epochs(el).notes = struct(...
                                    'epoch_group_id',n,'epoch_block_id',mm+m,'epoch_id',ell+el,...
                                    'entry_time',parseNoteTime(note.time),'text',note.text,...
                                    'note_index',num2cell(1:numel(note)));
                            end
                            
                            epochs(el).epoch_id = ell+el;
                            [epochs(el).epoch_start_time, epochs(el).epoch_duration] = parseDOTNETms(...
                                hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Attributes,...
                                experiment_start_day);
                            epochs(el).epoch_params = parseAttrs(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(2).Attributes);
                            
                            for k=1:nChans
                                epoch_channels(el,k).sample_rate = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(3).Groups(k).Attributes,'sampleRate');
                                epoch_channels(el,k).sample_rate_units = parseAttr(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(3).Groups(k).Attributes,'sampleRateUnits');
                                channel_str = strsplit(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(3).Groups(k).Name,'/');
                                channel_str = strsplit(channel_str{end},'-');
                                epoch_channels(el,k).channel_name = channel_str{1};
                                epoch_channels(el,k).epoch_id = ell+el;
                                
                                raw_data = h5read(fpath,...
                                    horzcat(hinfo.Groups(1).Groups(2).Groups(n).Groups(1).Groups(m).Groups(1).Groups(el).Groups(3).Groups(k).Name,'/data')...
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
                            chan_name = sprintf('channel_%d_units',k);
                            channels(k) = rmfield(epoch_channels(end,k),{'raw_data','epoch_id','sample_rate_units','units'});
                            epoch_blocks(m).protocol_params.(chan_name) = epoch_channels(end,k).units;
                            assert(all(strcmp({epoch_channels(:,k).channel_name}, channels(k).channel_name)),'Mis-matching channel names in epoch block!');
                            assert(all(strcmp({epoch_channels(:,k).sample_rate_units}, 'Hz')),'Sample rate not in Hz!');
                            assert(all(strcmp({epoch_channels(:,k).units}, epoch_blocks(m).protocol_params.(chan_name))),'Multiple channel units in epoch block!');
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
                % t = [arrayfun(@(a) strrep(a.Name,' ',''),attrs,'uni',0)';{attrs(:).Value}];
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
            
            function note_times = parseNoteTime(time_struct)
                note_times = mat2cell(datestr(...
                    datetime(uint64([time_struct.ticks]),...
                    'convertfrom','.net',...
                    'timezone',num2str(time_struct(1).offsetHours)),...
                    'YYYY-mm-DD HH:MM:SS'),ones(numel(time_struct),1));
                %assumes that all the entries have the same timezone :)
            end
            
            function sort_keys_by_start_time()
                [~,i] = sort({key.epoch_groups(:).epoch_group_start_time});
                [~,iA] = sort(i);
                
                f = fieldnames(key);
                for k = 1:numel(f)
                    %loop through each field
                    if isstruct(key.(f{k})) && isfield(key.(f{k}), 'epoch_group_id')
                        %grab the epoch group ids and re-label them
                        t = num2cell(iA([key.(f{k}).epoch_group_id]));
                        
                        %update all the entries for this field at once
                        [key.(f{k})(:).epoch_group_id] = t{:};
                    end
                end
                
                [~,i] = sort({key.epoch_blocks(:).epoch_block_start_time});
                [~,iA] = sort(i);
                
                f = fieldnames(key);
                for k = 1:numel(f)
                    if isstruct(key.(f{k})) && isfield(key.(f{k}), 'epoch_block_id')
                        t = num2cell(iA([key.(f{k}).epoch_block_id]));
                        [key.(f{k})(:).epoch_block_id] = t{:};
                    end
                end
                
                %note epoch times are numeric, for precision reasons
                %thus the start times are grouped using [] instead of {}
                [~,i] = sort([key.epochs(:).epoch_start_time]);
                [~,iA] = sort(i);
                
                f = fieldnames(key);
                for k = 1:numel(f)
                    if isstruct(key.(f{k})) && isfield(key.(f{k}), 'epoch_id')
                        t = num2cell(iA([key.(f{k}).epoch_id]));
                        [key.(f{k})(:).epoch_id] = t{:};
                    end
                end
                
            end
        end
        
        function key = parseParams(self,key)
            block_params = rmfield(key.epoch_blocks,{'epoch_block_start_time','epoch_block_end_time'});
            epoch_params = rmfield(key.epochs,{'epoch_start_time','epoch_duration'});
            key.epoch_blocks = rmfield(key.epoch_blocks,'protocol_params');
            key.epochs = rmfield(key.epochs,'epoch_params');
            
            %% parse electrode settings (easy!)
            key.epoch_block_electrode_settings = repmat(rmfield(block_params,{'protocol_params','protocol_name'}),2,1);
            [key.epoch_block_electrode_settings(1,:).channel_name] = deal('Amp1');
            
            has_units = find(arrayfun(@(p) isfield(p.protocol_params,'channel_1_units'), block_params));
            is_pa = arrayfun(@(p) strcmp(p.protocol_params.channel_1_units,'pA'), block_params(has_units));
            [key.epoch_block_electrode_settings(1,has_units(is_pa)).recording_mode] = deal('Voltage clamp');
            [key.epoch_block_electrode_settings(1,has_units(~is_pa)).recording_mode] = deal('Current clamp');
            
            hold = arrayfun(@(p) p.protocol_params.chan1Hold,block_params,'uni',0);
            [key.epoch_block_electrode_settings(1,:).hold] = hold{:};
            amp_mode = arrayfun(@(p) p.protocol_params.chan1Mode,block_params,'uni',0);
            [key.epoch_block_electrode_settings(1,:).amp_mode] = amp_mode{:};
            
            [key.epoch_block_electrode_settings(2,:).channel_name] = deal('Amp2');
            has_units = find(arrayfun(@(p) isfield(p.protocol_params,'channel_2_units'), block_params));
            is_pa = arrayfun(@(p) strcmp(p.protocol_params.channel_2_units,'pA'), block_params(has_units));
            [key.epoch_block_electrode_settings(2,has_units(is_pa)).recording_mode] = deal('Voltage clamp');
            [key.epoch_block_electrode_settings(2,has_units(~is_pa)).recording_mode] = deal('Current clamp');
            
            hold = arrayfun(@(p) p.protocol_params.chan2Hold,block_params,'uni',0);
            [key.epoch_block_electrode_settings(2,:).hold] = hold{:};
            amp_mode = arrayfun(@(p) p.protocol_params.chan2Mode,block_params,'uni',0);
            [key.epoch_block_electrode_settings(2,:).amp_mode] = amp_mode{:};
            
            key.epoch_block_electrode_settings(strcmp({key.epoch_block_electrode_settings(:).amp_mode},'Off')) = [];
            
            %% parse a couple params that belong on the experiment
            hasMPP = find(arrayfun(@(p) isfield(p.epoch_params,'micronsPerPixel'), epoch_params));
            key.microns_per_pixel = epoch_params(hasMPP(end)).epoch_params.micronsPerPixel;
            assert(all(arrayfun(@(p) p.epoch_params.micronsPerPixel, epoch_params(hasMPP)) == key.microns_per_pixel),'Microns per pixel changed during experiment!');
            
            hasAO = find(arrayfun(@(p) isfield(p.epoch_params,'angleOffsetFromRig'), epoch_params));
            key.angle_offset = epoch_params(hasAO(end)).epoch_params.angleOffsetFromRig;
            assert(all(arrayfun(@(p) p.epoch_params.angleOffsetFromRig, epoch_params(hasAO)) == key.angle_offset),'Angle offset changed during experiment!');
            
            %% parse settings that should exist for every protocol (inherits from BaseProtocol)
            p = arrayfun(@(p) p.protocol_params.preTime,block_params,'uni',0);
            s = arrayfun(@(p) p.protocol_params.stimTime,block_params,'uni',0);
            t = arrayfun(@(p) p.protocol_params.tailTime,block_params,'uni',0);
            %version??
            key.epoch_block_settings = struct('pre_time',p,'stim_time',s,'tail_time',t);
            
            %% parse projector settings
            %idea:
            %   main table has settings common to stage protocol...
            %       NDF, offsets, frame_rate, prerender,combinationMode??...
            %   sub table has settings common to LEDs
            %       color (fk), value, Rstar
            % tbd: patternID, foregroundRstar, backgroundRstar?
            
            
            %% the remaining settings are all defined on a protocol level
            
            
        end
    end
    
    
end