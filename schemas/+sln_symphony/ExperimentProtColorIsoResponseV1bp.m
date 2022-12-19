%{
#Block parameters for ColorIsoResponse (1) 
-> sln_symphony.ExperimentEpochBlock
---
annulus_mode : enum('F','T')
annulus_inner_diameter : float
annulus_outer_diameter : float
mean_level_1 : float
mean_level_2 : float
pre_time : float
rstar_mean : float
spot_diameter : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtColorIsoResponseV1bp < sln_symphony.ExperimentProtocol
    properties

        %attributes to be renamed
        renamed_attributes = struct();

        %attributes to be removed from the key
        dropped_attributes = {'session_id', 'color_combination_mode'};
    end
    methods
        function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
    		%add entities to the key based on others

            for i=1:length(block_key)
                if block_key(i).annulus_mode
                    block_key(i).annulus_mode = 'T';
                else
                    block_key(i).annulus_mode = 'F';
                end
        	end
        end
    end
end
