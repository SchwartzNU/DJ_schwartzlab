%{
#Block parameters for DriftingTexture (3) 
-> sln_symphony.ExperimentEpochBlock
---
aperture_diameter : float
chirp_start : float
mean_level : float
movement_delay : float
number_of_angles : smallint unsigned
number_of_cycles : smallint unsigned
pre_time : float
random_seed : float
motion_seed : float
random_motion : float
single_angle : smallint
smooth_motion_scale : smallint unsigned
res_scale_factor : float
rstar_mean : float
single_dimension : float
speed : float
stim_time : float
tail_time : float
texture_scale : float
uniform_distribution : float
%}
classdef ExperimentProtDriftingTextureV3bp < sln_symphony.ExperimentProtocol
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
