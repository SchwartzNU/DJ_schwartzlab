%{
#An experiment using Symphony DAS
file_name: varchar(64)
---
-> sln_lab.Rig
-> sln_symphony.Calibration
experiment_start_time: datetime
experiment_end_time: datetime
symphony_major_version: tinyint unsigned
symphony_minor_version: tinyint unsigned
symphony_patch_version: tinyint unsigned
symphony_revision_version: tinyint unsigned
%}
classdef Experiment < dj.Manual    
    methods
        
        function [key,success] = insert(self, key)
            if self.schema.conn.inTransaction
                error('Cannot insert Symphony data while in transaction. Please commit or cancel transaction and try again.');
                %the issue is that we may need to create new tables
                %but creating new tables breaks transactions (a dj bug?)
            end
            if isempty(which('symphonyui.core.PropertyDescriptor'))
                error('Cannot access Symphony property descriptors. Is Symphony on the path?');
            end
            success = false;
            %make sure all the tables are already in the db, otherwise transaction will break
            all_parts = dir(fileparts(which(class(self))));
            all_parts = {all_parts(...
                startsWith({all_parts(:).name},'Experiment') | ...
                startsWith({all_parts(:).name},'Calibration')...
                ).name};
            all_parts = cellfun(@(x) strsplit(x,'.'), all_parts, 'uni', 0);
            all_parts = vertcat(all_parts{:});
            all_parts = all_parts(:,1);
            all_parts = setdiff(all_parts, {'ExperimentProtocol','ExperimentProtocols','ExperimentPart'});

            all_loaded = self.schema.classNames;
            all_loaded = cellfun(@(x) strsplit(x,'.'), all_loaded, 'uni', 0);
            all_loaded = vertcat(all_loaded{:});
            if ~isempty(all_loaded)
                all_loaded = all_loaded(:,2);
            end

            %getting the plain table name forces insertion into the
            %database
            cellfun(@(x)feval(['sln_symphony.',x]).plainTableName, setdiff(all_parts, all_loaded),'uni',0);


            if isa(key,'char')
                key = loadSymphony2(fullfile(getenv('RAW_DATA_FOLDER'), key));
            elseif ~isa(key,'struct') 
                error('Key must be the name of a file or a struct derived from a Symphony file.');
            end
            
            %TODO: do this elsewhere?
            t = cellfun(@(x) changeCase(x,'snake'),{key.epoch_blocks(:).protocol_name},'uni',0);
            [key.epoch_blocks(:).protocol_name] = t{:};
            
            
            self.schema.conn.startTransaction;
            try
                channels = unique({key.channels(:).channel_name});
                existing_channels = fetch(sln_symphony.Channel & struct('channel_name',channels));
                missing_channels = setdiff(channels, {existing_channels(:).channel_name});
                if ~isempty(missing_channels)
                    missing_text = sprintf('\n\t> %s',missing_channels{:});
                    names_text = sprintf('''%s'',',missing_channels{:});
                    missing_text = sprintf(...
                        '%s\nTo insert all, use:\n\tsln_symphony.Channel().insert({%s}'');',...
                        missing_text,names_text(1:end-1));
                    error(['Channels were missing from the database. '...
                        'You must manually insert these in '...
                        'the Channel table or rename them in the key:%s'], missing_text); %#ok<*SPWRN>
                end
                key.experiment.calibration_id = insertIfNotEmpty(sln_symphony.Calibration(), key.calibration);
                for r=1:length(key.retinas)
                    if ~isfield(key.retinas(r), 'animal_id') || ~isnumeric(key.retinas(r).animal_id)
                        key.retinas(r)
                        DJID = input('Enter animal_id for this retina: ');
                        key.retinas(r).animal_id = DJID;
                    end
                    %TODO: deal with unknown eyes
%                     if ~isfield(key.retinas(r), 'side') || strcmp(key.retinas(r).side, 'unknown')
%                         q_left = sln_animal.Eye & sprintf('animal_id=%d', key.retinas(r).animal_id) & 'side="Left"';
%                         disp('Deleting left eye because unknown was entered');
%                         del(q_left);
%                         q_right = sln_animal.Eye & sprintf('animal_id=%d', key.retinas(r).animal_id) & 'side="Right"';
%                         disp('Deleting right eye because unknown was entered');
%                         del(q_right);
%                         q = sln_animal.Eye & sprintf('animal_id=%d', key.retinas(r).animal_id) & 'side="Unknown1"';
%                         if q.exists
%                             key.retinas(r).side = 'Unknown2';
%                             insert(sln_animal.Eye, {key.retinas(r).animal_id, 'Unknown2'})
%                         else
%                             key.retinas(r).side = 'Unknown1';
%                             insert(sln_animal.Eye, {key.retinas(r).animal_id, 'Unknown1'})
%                         end
%                     end
                end 
                insert@dj.Manual(self, key.experiment);
                insertIfNotEmpty(sln_symphony.ExperimentSource(),key.sources);
                insertIfNotEmpty(sln_symphony.ExperimentRetina(),key.retinas);
                insertIfNotEmpty(sln_symphony.ExperimentCell(),key.cells);
                insertIfNotEmpty(sln_symphony.ExperimentCellPair(),key.cell_pairs);
                insertIfNotEmpty(sln_symphony.ExperimentEpochGroup(),key.epoch_groups);
                
                insertIfNotEmpty(sln_symphony.ExperimentProtocols(),key.epoch_blocks, key.epochs);
                
                insertIfNotEmpty(sln_symphony.ExperimentChannel(),key.channels);
                
                c = onCleanup(@() warning('on','MATLAB:MKDIR:DirectoryExists'));                
                warning('off','MATLAB:MKDIR:DirectoryExists');
                insertIfNotEmpty(sln_symphony.ExperimentEpochChannel(),key.epoch_channels);
                insertIfNotEmpty(sln_symphony.ExperimentElectrode(),key.electrodes);
                
                insertIfNotEmpty(sln_symphony.ExperimentNote(),key.experiment_notes);
                insertIfNotEmpty(sln_symphony.ExperimentSourceNote(),key.source_notes);
                insertIfNotEmpty(sln_symphony.ExperimentEpochGroupNote(),key.epoch_group_notes);
                insertIfNotEmpty(sln_symphony.ExperimentEpochBlockNote(),key.epoch_block_notes);
                insertIfNotEmpty(sln_symphony.ExperimentEpochNote(),key.epoch_notes);
                
            catch ME
                self.schema.conn.cancelTransaction;

                warning(getReport(ME, 'extended', 'hyperlinks', 'on'));
                warning('Table insertion failed. Key is available as output.');
                return;
            end
            self.schema.conn.commitTransaction;
            success = true;
        end
    end
end


function ret = insertIfNotEmpty(table, varargin)
    if ~isempty(varargin{1})
        table.canInsert = true;
        fprintf('Populating %s...', class(table));
        
        tic;
        ret = table.insert(varargin{:});
        fprintf(' done (took %.02f seconds).\n',toc);
    end
end