%{
# A cell from an animal
cell_unid: int unsigned auto_increment
---
-> sln_animal.Animal
-> [nullable] sln_symphony.ExperimentCell
-> [nullable] sln_image.CellImage
%}
classdef Cell < dj.Manual
end