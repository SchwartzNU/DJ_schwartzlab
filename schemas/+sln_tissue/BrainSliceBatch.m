%{
#describe the brain slice 
-> sln_tissue.Tissue
---
slicing_orientation: enum('Coronal', 'Saggital', 'Horizontal')
thickness: smallint unsigned
->sln_animal.Animal
%}

classdef BrainSliceBatch < dj.Manual
end
