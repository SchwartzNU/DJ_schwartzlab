%{
#b parameters for TemporalNoise (2) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : float
aperture : float
color_noise_distribution : varchar(64)
color_noise_mode : varchar(64)
contrast : float
mean_level : float
pre_time : float
rstar_mean : float
seed_change_mode : varchar(64)
seed_start_value : float
spot_mean_level : float
stim_time : float
tail_time : float
constant_frame_dwell: float
number_of_epochs_per_frame_dwell : float
total_num_epochs : smallint unsigned
%}
classdef ExperimentProtTemporalNoiseV2bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'frame_dwells', 'frame_dwell_mode'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
