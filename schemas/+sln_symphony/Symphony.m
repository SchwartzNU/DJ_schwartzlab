%{
#A handle to a Symphony raw data file
file_name: varchar(64)
---
-> sl.Rig
experiment_start_time: datetime
experiment_end_time: datetime
symphony_major_version: tinyint unsigned
symphony_minor_version: tinyint unsigned
symphony_patch_version: tinyint unsigned
symphony_revision_version: tinyint unsigned
microns_per_pixel = NULL : float
angle_offset = NULL : float
%}
classdef Symphony < dj.Manual    
    methods
        
        function key = insert(self, key)
            if self.schema.conn.inTransaction
                error('Cannot insert Symphony data while in transaction. Please commit or cancel transaction and try again.');
            end
            %make sure all the tables are already in the db, otherwise transaction will break
            all_parts = dir(fileparts(which(class(self))));
            all_parts = {all_parts(startsWith({all_parts(:).name},'Symphony')).name};
            all_parts = cellfun(@(x) strsplit(x,'.'), all_parts, 'uni', 0);
            all_parts = vertcat(all_parts{:});
            all_parts = all_parts(:,1);
            all_parts = setdiff(all_parts, {'SymphonyProtocol','SymphonyProtocols'});

            all_loaded = self.schema.classNames;
            all_loaded = cellfun(@(x) strsplit(x,'.'), all_loaded, 'uni', 0);
            all_loaded = vertcat(all_loaded{:});
            all_loaded = all_loaded(:,2);
            
            %getting the plain table name forces insertion into the
            %database
            cellfun(@(x) feval(['sln_symphony.',x]).plainTableName, setdiff(all_parts, all_loaded),'uni',0);


            if isa(key,'char')
                key = loadSymphony2(fullfile(getenv('RAW_DATA_FOLDER'), key));
            elseif ~isa(key,'struct') 
                error('Key must be the name of a file or a struct derived from a Symphony file.');
            end
            
            self.schema.conn.startTransaction;
            try
                insert@dj.Manual(self, key.experiment);
                insertIfNotEmpty(sln_symphony.SymphonySource(),key.sources);
                insertIfNotEmpty(sln_symphony.SymphonyRetina(),key.retinas);
                insertIfNotEmpty(sln_symphony.SymphonyCell(),key.cells);
                insertIfNotEmpty(sln_symphony.SymphonyCellPair(),key.cell_pairs);
                insertIfNotEmpty(sln_symphony.SymphonyEpochGroup(),key.epoch_groups);
                
                %these have to occur together?
                insertIfNotEmpty(sln_symphony.SymphonyProtocols(),key.epoch_blocks, key.epochs);
%                 sln_symphony.SymphonyEpochBlock().insert(key.epoch_blocks);
%                 sln_symphony.SymphonyEpoch().insert(key.epochs);
                
                insertIfNotEmpty(sln_symphony.SymphonyChannel(),key.channels);
                insertIfNotEmpty(sln_symphony.SymphonyEpochChannel(),key.epoch_channels);
                insertIfNotEmpty(sln_symphony.SymphonyElectrode(),key.electrodes);
                
                insertIfNotEmpty(sln_symphony.SymphonyNote(),key.experiment_notes);
                insertIfNotEmpty(sln_symphony.SymphonySourceNote(),key.source_notes);
                insertIfNotEmpty(sln_symphony.SymphonyEpochGroupNote(),key.epoch_group_notes);
                insertIfNotEmpty(sln_symphony.SymphonyEpochBlockNote(),key.epoch_block_notes);
                insertIfNotEmpty(sln_symphony.SymphonyEpochNote(),key.epoch_notes);
                
            catch ME
                self.schema.conn.cancelTransaction;

                warning('Table creation failed. Key is available as output.');
                disp(getReport(ME, 'extended', 'hyperlinks', 'on'));
                return;
            end
            self.schema.conn.commitTransaction;
        end
    end
end


function insertIfNotEmpty(table, varargin)
    if ~isempty(varargin{1})
        table.insert(varargin{:});
    end
end