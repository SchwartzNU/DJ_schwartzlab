%{
#Slice the brain
-> sln_tissue.Task
---
thickness : int unsigned # microns per slice
-> sln_animal.BrainArea
%}

classdef Slice < dj.Manual
    
end