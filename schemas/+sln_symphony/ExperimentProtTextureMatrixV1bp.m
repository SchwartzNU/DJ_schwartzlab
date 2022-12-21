%{
#b parameters for TextureMatrix (1) 
-> sln_symphony.ExperimentEpochBlock
---
aperture_diameter : float
effective_pixel_size : float
log_scaling : enum('F','T') #bool
max_blur_sigma : float
max_half_max_scale : float
mean_level : float
min_blur_sigma : float
min_half_max_scale : float
num_conditions : float
num_of_blur_steps : float
num_random_seeds : float
number_of_cycles : smallint unsigned
pre_time : float
res_scale_factor : float
rstar_mean : float
single_dimension : float
stim_time : float
tail_time : float
uniform_distribution : float
%}
classdef ExperimentProtTextureMatrixV1bp < sln_symphony.ExperimentProtocol
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
