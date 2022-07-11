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
            type = sln_cell.AssignType * sln_cell.CellEvent & 'LIMIT 1 PER cell_unid ORDER BY entry_time DESC';
        end
    end
end