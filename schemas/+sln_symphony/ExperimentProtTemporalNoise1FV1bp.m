%{
#b parameters for TemporalNoise1F (1) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : float
aperture : float
color_noise_distribution : varchar(64)
color_noise_mode : varchar(64)
contrast : float
frame_dwell : float
mean_level : float
number_of_epochs_per_beta : float
pre_time : float
rstar_mean : float
seed_change_mode : varchar(64)
seed_start_value : float
spot_mean_level : float
stim_time : float
tail_time : float
total_num_epochs : smallint unsigned
%}
classdef ExperimentProtTemporalNoise1FV1bp < sln_symphony.ExperimentProtocol
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
