%{
#
-> sln_cell.CellEvent
---
-> sln_cell.CellType

%}
classdef AssignType < dj.Manual
    methods(Static)
        function type = current()
            type = sln_cell.AssignType * sln_cell.CellEvent & 'LIMIT 1 PER cell_unid ORDER BY entry_time DESC';
        end

        function type = initial()
            type = sln_cell.AssignType * sln_cell.CellEvent & 'LIMIT 1 PER cell_unid ORDER BY entry_time ASC';
        end

        function type = fetch_current_type(cell_id) %fetch the lastest cell type
            query = sprintf('cell_unid = %d', cell_id);
            types = fetch(sln_cell.CellEvent * sln_cell.AssignType & query, '*');
            [~ , indx] = max([types.event_id]);
            type = types(indx).cell_type;
        end
    end
end