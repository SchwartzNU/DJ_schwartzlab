%{
#b parameters for WhiteToPinkTemporalNoise (1) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : float
aperture : float
beta_1 : float
beta_2 : float
frame_dwell : float
mean_level : float
number_of_epochs : smallint unsigned
pre_time : float
seed_change_mode : varchar(64)
seed_start_value : float
spot_mean_level : float
stim_contrast_1 : float
stim_contrast_2 : float
stim_time : float
tail_time : float
time_1 : float
time_2 : float
total_num_epochs : float
%}
classdef ExperimentProtWhiteToPinkTemporalNoiseV1bp < sln_symphony.ExperimentProtocol
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
