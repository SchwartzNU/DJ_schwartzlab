%{
#Stain tissue 
-> sln_tissue.Task
---
(reagent_1) -> sln_tissue.StainReagent
(reagent_2) -> [nullable] sln_tissue.StainReagent
%}

classdef Stain < dj.Manual
    
end