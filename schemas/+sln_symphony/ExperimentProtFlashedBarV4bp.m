%{
#Block parameters for FlashedBar (3) 
-> sln_symphony.ExperimentEpochBlock
---
bar_length : float
bar_width : float
intensity : float
mean_level : float
number_of_angles : smallint unsigned
number_of_cycles : smallint unsigned
pre_time : float
rstar_mean : float
stim_time : float
tail_time : float
color_combination_mode : varchar(32)
background_pattern = NULL : tinyint unsigned
primary_object_pattern : tinyint unsigned
secondary_object_pattern : tinyint unsigned
%}
classdef ExperimentProtFlashedBarV4bp < sln_symphony.ExperimentProtocol
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
