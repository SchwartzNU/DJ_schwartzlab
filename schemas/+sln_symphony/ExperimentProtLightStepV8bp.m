%{
#Block parameters for LightStep (8) 
-> sln_symphony.ExperimentEpochBlock
---
intensity : float
mean_level : float
number_of_epochs : smallint unsigned
pre_time : float
rstar_mean = NULL : float
spot_size : float
stim_time : float
tail_time : float
color_combination_mode : varchar(32)
background_pattern : smallint unsigned
primary_object_pattern : smallint unsigned
secondary_object_pattern : smallint unsigned
%}
classdef ExperimentProtLightStepV8bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'alternate_patterns'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
