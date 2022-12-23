%{
#b parameters for CenterSurroundNoise (6) 
-> sln_symphony.ExperimentEpochBlock
---
annulus_inner_diameter : float
annulus_outer_diameter : float
center_diameter : float
color_noise_mode : varchar(64)
frame_dwell : float
location_mode : varchar(64)
number_of_epochs : smallint unsigned
pre_time : float
rstar_mean : float
seed_change_mode : varchar(64)
seed_start_value : float
stim_time : float
tail_time : float
color_combination_mode : varchar(32)
contrast_1 : float
contrast_2 : float
mean_level_1 : float
mean_level_2 : float
%}
classdef ExperimentProtCenterSurroundNoiseV6bp < sln_symphony.ExperimentProtocol
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
