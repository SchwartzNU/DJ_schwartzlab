%{
# A brain cell from an animal
cell_unid                   : int unsigned AUTO_INCREMENT   # 
---
-> sln_animal.Animal
-> [nullable, unique] sln_symphony.ExperimentBrainCell
%}
classdef BrainCell < dj.Manual
end
