%{
# An event that tracks all the times a cell's type has been assigned
# Sort for latest to get the current cell type

typing_id : int unsigned autoincrement # automatically assigned on insert
---
-> sln_cell.Cell
-> sln_cell.Type
entry_time = CURRENT_TIMESTAMP: timestamp
%}
classdef CellTyping < dj.Manual
end