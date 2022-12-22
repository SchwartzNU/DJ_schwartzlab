%{
#b parameters for TextureMatrix (2) 
-> sln_symphony.ExperimentEpochBlock
---
aperture_diameter : float
log_scaling : enum('F','T') #bool
max_texture_scale : float
min_texture_scale : float
num_of_scale_steps : smallint unsigned
mean_level : float
num_conditions : float
num_random_seeds : float
number_of_cycles : smallint unsigned
pre_time : float
res_scale_factor : float
rstar_mean : float
single_dimension : float
stim_time : float
tail_time : float
uniform_distribution : float
background_pattern : smallint unsigned
primary_object_pattern : smallint unsigned
secondary_object_pattern : smallint unsigned
mstar_intensity : float
sstar_intensity : float
color_combination_mode : varchar(32)
%}
classdef ExperimentProtTextureMatrixV2bp < sln_symphony.ExperimentProtocol
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
