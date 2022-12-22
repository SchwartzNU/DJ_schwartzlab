%{
#b parameters for ColorResponse (2) 
-> sln_symphony.ExperimentEpochBlock
---
background_pattern : float
base_color : tinyblob
color_change_mode : varchar(64)
contrast : float
enable_surround : float
intensity : float
mean_level : float
mstar_intensity : float
num_ramp_steps : float
number_of_cycles : smallint unsigned
pre_time : float
primary_object_pattern : float
rstar_mean : float
secondary_object_pattern : float
spot_diameter : float
sstar_intensity : float
stim_time : float
surround_diameter : float
tail_time : float
%}
classdef ExperimentProtColorResponseV2bp < sln_symphony.ExperimentProtocol
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
