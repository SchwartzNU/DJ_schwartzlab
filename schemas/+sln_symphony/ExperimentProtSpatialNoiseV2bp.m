%{
#Block parameters for SpatialNoise (2) 
-> sln_symphony.ExperimentEpochBlock
---
color_noise_mode : varchar(64)
contrast : float
frame_dwell : float
mean_level : float
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
%}
classdef ExperimentProtSpatialNoiseV2bp < sln_symphony.ExperimentProtocol
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
