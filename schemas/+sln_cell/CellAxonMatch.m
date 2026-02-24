%{
#match between axon and the RGC 
->sln_cell.Axon
---
->sln_cell.Cell
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
-> sln_lab.User
certainty: enum('Certain', 'Uncertain')
%}

classdef CellAxonMatch <dj.Manual
    methods (Static)
        function insertMatch(axonId, cellId, userName, certainty)
            key.axon_id = axonId;
            key.cell_unid = cellId;
            key.user_name = userName;
            key.certainty = certainty;

            %check if there is already one
            result = fetch(sln_cell.CellAxonMatch & key);
            if (~isempty(result))
                warning('This axon - cell pair already exists!\n');
                return
            end

            try
                C = dj.conn;
                C.startTransaction;
                insert(sln_cell.CellAxonMatch, key);
                C.commitTransaction;
                fprintf('Insert successful! Cell %d is associated with axon(s) below:\n', cellId);

                qs = sprintf('cell_unid = %d', cellId);
                allaxons = fetch(sln_cell.CellAxonMatch & qs);
                for i = 1:length(allaxons)
                    fprintf('Axon ID: %d\n', allaxons(i).axon_id);
                end

            catch ME
                throw(ME);
            end

            % Insert a new match entry into the database

        end
    end
end