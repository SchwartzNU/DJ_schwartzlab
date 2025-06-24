%{
#
-> sln_cell.CellEvent
---
-> sln_cell.CellType

%}
classdef AssignBrainCellType < dj.Manual
    methods(Static)
        function type = current()
            type = sln_cell.AssignBrainCellType * sln_cell.BrainCellEvent & 'LIMIT 1 PER cell_unid ORDER BY entry_time DESC';
        end

        function type = initial()
            type = sln_cell.AssignBrainCellType * sln_cell.BrainCellEvent & 'LIMIT 1 PER cell_unid ORDER BY entry_time ASC';
        end
    end
end