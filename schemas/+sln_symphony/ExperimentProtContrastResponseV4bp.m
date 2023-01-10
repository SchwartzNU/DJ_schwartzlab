%{
#Block parameters for ContrastResponse (4) 
-> sln_symphony.ExperimentEpochBlock
---
contrast_direction : enum('negative','positive','both')
max_contrast : float
mean_level : float
min_contrast : float
number_of_contrast_steps : smallint unsigned
number_of_cycles : smallint unsigned
pre_time : float
real_number_of_contrast_steps : smallint unsigned
spot_diameter : float
stim_time : float
tail_time : float
rstar_mean = NULL : float
background_pattern : smallint unsigned
green_or_uv_led : smallint unsigned
primary_object_pattern : smallint unsigned
red_or_green_led : smallint unsigned
secondary_object_pattern : smallint unsigned
%}
classdef ExperimentProtContrastResponseV4bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'red_led'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
