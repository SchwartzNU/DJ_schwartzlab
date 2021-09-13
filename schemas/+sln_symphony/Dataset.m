%{
# A user-defined group of epochs for analysis
-> sln_symphony.Symphony
dataset_name: varchar(64)
%}
classdef Dataset < dj.Manual
    methods
        
        function insert(self, key)
            transacted = false;
            if self.schema.conn.inTransaction
                transacted = true;
            else
                self.schema.conn.startTransaction;
            end
            try
                insert@dj.Manual(self, rmfield(key, {'cells','epoch_channels'}));
                sln_symphony.DatasetCell().insert(key.cells);
                sln_symphony.DatasetEpochChannel().insert(key.epoch_channels);                
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
