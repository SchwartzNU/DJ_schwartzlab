%{
#Block parameters for LightStep (7) 
-> sln_symphony.ExperimentEpochBlock
---
alternate_patterns : tinyint unsigned
intensity : float
mean_level : float
number_of_epochs : smallint unsigned
pre_time : float
rstar_mean = NULL : float
spot_size : float
stim_time : float
tail_time : float
mstar_intensity : float
sstar_intensity : float
color_combination_mode : varchar(32)
background_pattern : smallint unsigned
primary_object_pattern : smallint unsigned
secondary_object_pattern : smallint unsigned
%}
classdef ExperimentProtLightStepV7bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
