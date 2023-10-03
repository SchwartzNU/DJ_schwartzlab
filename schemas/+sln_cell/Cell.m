%{
# A cell from an animal
cell_unid                   : int unsigned AUTO_INCREMENT   # 
---
-> sln_animal.Animal
-> [nullable, unique] sln_symphony.ExperimentCell
-> [nullable] sln_image.CellImage
%}
classdef Cell < dj.Manual
end
