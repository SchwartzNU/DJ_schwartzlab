%{
#Block parameters for MovingBar (4) 
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
stim_time : float
tail_time : float
background_pattern : smallint unsigned
green_or_uv_led : smallint unsigned
primary_object_pattern : smallint unsigned
red_or_green_led : smallint unsigned
secondary_object_pattern : smallint unsigned
%}
classdef ExperimentProtMovingBarV4bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key)  %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
