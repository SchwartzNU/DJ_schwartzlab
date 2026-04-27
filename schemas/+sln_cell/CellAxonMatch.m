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
        function inssertMatch_arrays(axonAr, cellAr, userName, certaintyAr)
            %check array lengths
            lengths = zeros([3, 1]);
            lengths(1) = numel(axonAr);
            lengths(2) = numel(cellAr);
            lengths(3) = numel(certaintyAr);

            if numunique(lengths)~=1
                error('Check the input arrays! Multiple lengths! No insertion\n');
            end

            %try insert
            try
                for i = 1:lengths(1)
                    sln_cell.CellAxonMatch.insertMatch_single(axonAr(i), ...
                        cellAr(i), userName, certaintyAr{i});
                end
            catch ME
                throw (ME);
            end

        end

        function insertMatch_single(axonId, cellId, userName, certainty)
            key.axon_id = axonId;
            key.cell_unid = cellId;
            key.user_name = userName;
            key.certainty = certainty;

            %check if there is already one
            result = fetch(sln_cell.CellAxonMatch & key);
            if (~isempty(result))
                error('This axon - cell pair already exists!\n');
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