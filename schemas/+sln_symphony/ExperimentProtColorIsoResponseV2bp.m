%{
#Block parameters for ColorIsoResponse (2) 
-> sln_symphony.ExperimentEpochBlock
---
annulus_mode : enum('F','T')
annulus_inner_diameter : float
annulus_outer_diameter : float
pre_time : float
rstar_mean : float
spot_diameter : float
stim_time : float
tail_time : float
background_pattern : tinyint unsigned 
base_intensity_1 : float
base_intensity_2 : float
enable_surround : tinyint unsigned 
primary_object_pattern : tinyint unsigned 
secondary_object_pattern : tinyint unsigned 
surround_diameter : float
%}
classdef ExperimentProtColorIsoResponseV2bp < sln_symphony.ExperimentProtocol
    properties

        %attributes to be renamed
        renamed_attributes = struct();

        %attributes to be removed from the key
        dropped_attributes = {'session_id', 'color_combination_mode'};
    end
    methods
        function block_key_new = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
            %add entities to the key based on others

            for i=1:length(block_key)
                b = block_key(i);
                if isfield(b,'annulus_mode')
                    if b.annulus_mode
                        b.annulus_mode = 'T';
                    else
                        b.annulus_mode = 'F';
                    end
                else
                    b.annulus_mode = 'F';
                end
                block_key_new(i) = b;
            end
        end
    end
end
