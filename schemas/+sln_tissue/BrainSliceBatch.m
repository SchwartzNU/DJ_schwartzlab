%{
#describe the brain slice 
-> sln_tissue.Brain
---
slicing_orientation: enum('Coronal', 'Saggital', 'Horizontal')
thickness: smallint unsigned
%}

classdef BrainSliceBatch < dj.Manual
methods
    function slicebatchid = addBrainSliceBatch(keys)
        
    end
end
end