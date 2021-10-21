%{
# A user-defined group of epochs for analysis
-> sln_symphony.ExperimentSource
dataset_name: varchar(64)
%}
classdef Dataset < dj.Manual
    methods
        
        function insert(self, celldata)
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

            transacted = false;
            if self.schema.conn.inTransaction
                transacted = true;
            else
                self.schema.conn.startTransaction;
            end
            try
                insert@dj.Manual(self, rmfield(key, {'epochs'}));
                table = sln_symphony.DatasetEpoch();
                table.canInsert = true;
                table.insert(...
                vertcat(key(:).epochs));  
                sln_symphony.SpikeTrain().insert(spikes);              
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
