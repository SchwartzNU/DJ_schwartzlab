%{
#Block parameters for SpatialNoise (5) 
-> sln_symphony.ExperimentEpochBlock
---
color_noise_mode : varchar(64)
frame_dwell : float
number_of_epochs : smallint unsigned
pre_time : float
resolution_x : float
resolution_y : float
rstar_mean : float
seed_change_mode : varchar(64)
seed_start_value : float
size_x : float
size_y : float
stim_time : float
tail_time : float
color_combination_mode : varchar(32)
contrast_1 : float
contrast_2 : float
contrast : float
mean_level_1 : float
mean_level_2 : float
mean_level : float
color_noise_distribution : varchar(32)
max_offset : float
offset_delta : float
%}
classdef ExperimentProtSpatialNoiseV5bp < sln_symphony.ExperimentProtocol
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
