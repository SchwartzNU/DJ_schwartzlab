%{
#Block parameters for MovingBar (8) 
-> sln_symphony.ExperimentEpochBlock
---
bar_length : float
bar_speed : float # (um/s)
bar_width : float
distance : float
intensity : float
mean_level : float
number_of_angles : smallint unsigned
number_of_cycles : smallint unsigned
pre_time : float
rstar_mean : float
single_edge_mode : float #should really be a bool
stim_time : float
tail_time : float
%}
classdef ExperimentProtMovingBarV8bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key)  %#ok<INUSL,INUSD>            
            for i=1:length(block_key)
                if isfield(block_key(i),'angle_offset')
                    if isempty(block_key(i).angle_offset) || isnan(block_key(i).angle_offset)
                        block_key(i).angle_offset = 0;
                    end
                end
            end
		%add entities to the key based on others
		end
	end
end
