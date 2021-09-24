classdef CellByEpoch < aka.Alias
    properties
        query = sln_symphony.SymphonyCell().proj('*','source_id->cell_id');
        %TODO: we probably want the sln_cell.Cell obj, not the
        %sln_symphony.SymphonyCell obj.
    end
    
    methods
        function self = CellByEpoch(epochObj)
            assert(nargin, 'CellByEpoch requires an Epoch object as input!');
            assert(...
                isa(epochObj,'sln_symphony.SymphonyEpoch') || isa(epochObj, 'aka.Epoch'),...
                sprintf('CellByEpoch expected an Epoch object, but a(n) %s was given',...
                class(epochObj)));
            self@aka.Alias({'*','cell_id->source_id'},epochObj * sln_symphony.SymphonyElectrode);
        end
    end
end