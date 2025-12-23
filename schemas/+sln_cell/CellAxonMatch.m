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
end