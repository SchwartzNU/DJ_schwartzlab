%{
#describe the brain slice 
-> sln_tissue.Tissue
->sln_animal.Animal
---
slicing_orientation: enum('Coronal', 'Saggital', 'Horizontal')
thickness: smallint unsigned
%}

classdef BrainSliceBatch < dj.Manual
methods
end
end
