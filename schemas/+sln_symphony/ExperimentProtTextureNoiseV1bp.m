%{
#b parameters for TextureNoise (1) 
-> sln_symphony.ExperimentEpochBlock
---
contrast : float
high_pass_spatial : float
high_pass_temporal : float
low_pass_spatial : float
mean_level : float
noise_power_distribution : float
num_repeats : smallint unsigned
num_seeds : smallint unsigned
peak_amplitude : float
peak_spatial_frequency : float
peak_width : float
pre_time : float
rstar_mean : float
seed_start_value : int
size_x : float
size_y : float
stim_time : float
tail_time : float
temporal_width : float
%}
classdef ExperimentProtTextureNoiseV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'antialias','rfm_emory', 'subsample_t'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
