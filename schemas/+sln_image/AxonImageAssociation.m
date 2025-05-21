%{
#association table showing RGC axons in the brain and cooresponding axonal images
->sln_cell.Axon
->sln_image.AxonInBrain
---
%}
classdef AxonImageAssociation< dj.Manual
    methods (Static)
        function new_axon_id = update_association(axon_id, image_id_array)
            %todo 
        end
    end
end