%{
#Block parameters for DriftingTexture (1) 
-> sln_symphony.ExperimentEpochBlock
---
aperture_diameter : float
chirp_start : float
mean_level : float
motion_lowpass_filter_params : tinyblob
motion_seed : float
movement_delay : float
movement_sensitivity : float
movement_sensitivity_step_size : float
number_of_angles : smallint unsigned
number_of_cycles : smallint unsigned
number_of_movement_sensitivity_steps : smallint unsigned
pre_time : float
random_motion : float
random_seed : float
res_scale_factor : float
rstar_mean : float
single_angle : float
single_dimension : float
speed : float
stim_time : float
tail_time : float
texture_scale : float
uniform_distribution : float
%}
classdef ExperimentProtDriftingTextureV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'rstarIntensity'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
