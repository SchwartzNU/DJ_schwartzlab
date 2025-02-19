%{
# A user-defined group of epochs for analysis
-> sln_symphony.ExperimentSource
dataset_name: varchar(64)
%}
classdef Dataset < dj.Manual
    methods

        function insert(self, key)
            N_epochs = length(key.epoch_id);
            key_ds_entry = rmfield(key,'epoch_id');
            key_no_ds = rmfield(key,{'dataset_name', 'epoch_id'});
%            dataset_ep = key_no_epochs;
%            dataset_ep.epoch_id = 0;
%            dataset_epochs_struct = repmat(dataset_ep,[N_epochs, 1]);
            for i=1:N_epochs
                ep = aka.Epoch & key_no_ds & sprintf('epoch_id=%d',key.epoch_id(i));
                dep = fetch(ep);
                dep.dataset_name = key.dataset_name;
                dataset_epochs_struct(i) = dep;
            end
            
            transacted = false;
            if self.schema.conn.inTransaction
                transacted = true;
            else
                self.schema.conn.startTransaction;
            end
            try                
                table = sln_symphony.DatasetEpoch();
                table.canInsert = true;
                %see if dataset_epochs are already in the DB 
                q = sln_symphony.DatasetEpoch & key_ds_entry;
                if q.exists
                    fprintf('overwriting dataset %s with %d existing epochs\n', key.dataset_name, q.count);
                    delQuick(q);
                    delQuick(sln_symphony.Dataset & key_ds_entry)                    
                    insert@dj.Manual(self, key_ds_entry);
                    table.insert(dataset_epochs_struct);
                else
                    insert@dj.Manual(self, key_ds_entry);
                    table.insert(dataset_epochs_struct);
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
%function insert_from_celldata(self, celldata)

        function insert_from_celldata(self, celldata)
            if ~isa(celldata,'cell')
                celldata = {celldata};
            end
            spikes = struct(...
                'file_name',{},...
                'source_id',{},...
                'epoch_group_id',{},...
                'epoch_block_id',{},...
                'epoch_id',{},...
                'channel_name',{},...
                'spike_indices',{},...
                'spike_count',{}...
                );
            key = struct(...
                'file_name', {},...
                'dataset_name',{},...
                'source_id',{},...
                'epochs',{});
            for i=1:numel(celldata)
                c = load(sprintf('%s%s',...
                    getenv('CELL_DATA_FOLDER'),celldata{i})).cellData;
                fname = c.attributes('fname');
                n = c.attributes('number');
                q = sln_symphony.ExperimentCell...
                    & sprintf('file_name="%s"',fname)...
                    & sprintf('cell_number = %d',n(1));
                cnt = count(q);
                if cnt < 1
                    error('Cell not found in database!');
                elseif cnt > 1
                    error('More than one matching cell!!');
                end

                q_id = fetch1(q,'source_id');
                q_e = fetch(q * sln_symphony.ExperimentEpoch);

                N = c.savedDataSets.length;
                emp = cell(N,1);
                key_i = struct(...
                    'file_name',repmat({fname},N,1),...
                    'dataset_name',c.savedDataSets.keys()',...
                    'source_id',q_id,...
                    'epochs',emp);
                for j=1:numel(key_i)
                    e_id = c.savedDataSets(key_i(j).dataset_name);
                    key_i(j).epochs = q_e(e_id);
                    [key_i(j).epochs(:).dataset_name] = deal(key_i(j).dataset_name);
                end
                key = vertcat(key,key_i);

                st = arrayfun(@(x) x.get('spikes_ch1'), c.epochs, 'uni', 0);
                j = cellfun(@(x) numel(x) == 1 && isnan(x), st);
                st = st(~j);
                sc = cellfun(@numel, st,'uni', 0);

                %TODO: do we want to check whether the trials are whole cell voltage clamp??
                %this could indicate an error with the raw data file,or just user error
                %maybe handle with an input flag...

                spikes_i = q_e(~j);
                [spikes_i(:).spike_indices] = deal(st{:});
                [spikes_i(:).spike_count] = deal(sc{:});
                [spikes_i(:).channel_name] = deal('Amp1');

                spikes = vertcat(spikes, spikes_i);
            end
            
            if isempty(key)
                warning('No datasets were found')
                return
            end

            transacted = false;
            if self.schema.conn.inTransaction
                transacted = true;
            else
                self.schema.conn.startTransaction;
            end
            try
                replace_epochs = false;
                replace_spikes = false;
                thisKey = rmfield(key, {'epochs'});
                thisDataset = self & thisKey;
                table = sln_symphony.DatasetEpoch();
                table.canInsert = true;

                if thisDataset.exists
                    N_datasets = length(thisKey);
                    for d=1:N_datasets
                        cur_dataset = self & thisKey(d);
                        if ~cur_dataset.exists
                            fprintf('inserting new datset %s\n', thisKey(d).dataset_name);
                            %insert@dj.Manual(self, thisKey(d));
                             dj.Manual.insert(self, thisKey(d));
                             table.insert(...
                                 vertcat(key(d).epochs));
                             if ~isempty(spikes(d))
                                 sln_symphony.SpikeTrain().insert(spikes(d),'REPLACE');
                             end
                        end
                    end
                    
                    if ~strcmp(getenv('skip'),'T')
                        user_resp = input('Datasets for this cell aleady in database. Overwrite spike trains (y|n)? \n', 's');
                        if strcmp(user_resp,'y')
                            replace_spikes = true;
                        else
                            replace_spikes = false;
                        end
                    else
                        disp('skipping because of environment variable');
                    end
                    if ~isempty(spikes)
                        if replace_spikes
                            disp('replacing spikes');
                            del(sln_symphony.SpikeTrain() & rmfield(spikes,{'spike_count','spike_indices'}), true);
                            sln_symphony.SpikeTrain().insert(spikes);
                        end
                    end
                else %first insert
                    %insert@dj.Manual(self, thisKey);
                    dj.Manual.insert(self, thisKey);
                    table.insert(...
                        vertcat(key(:).epochs));
                    if ~isempty(spikes)
                        sln_symphony.SpikeTrain().insert(spikes);
                    end
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
    end
end
