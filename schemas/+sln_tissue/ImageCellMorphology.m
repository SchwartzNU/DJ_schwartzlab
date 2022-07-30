%{
#Image cell morphology
-> sln_tissue.Task
---
-> sln_tissue.ColorChannel
-> sln_tissue.Scope
cell_number = NULL : int unsigned #number recorded from Symphony, NULL if not recorded
%}

classdef ImageCellMorphology < dj.Manual
    
end