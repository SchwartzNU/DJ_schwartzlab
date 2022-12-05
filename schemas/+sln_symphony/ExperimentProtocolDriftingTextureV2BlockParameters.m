%{
#Block parameters for DriftingTexture (2) 
-> sln_symphony.ExperimentEpochBlock
---
aperture_diameter : float
mean_level : float
movement_delay : float
number_of_angles : smallint unsigned
number_of_cycles : smallint unsigned
pattern_rate : float
pre_time : float
random_seed : float
res_scale_factor : float
rstar_mean : float
speed : float
stim_time : float
tail_time : float
texture_scale : float
uniform_distribution : float
%}
classdef ExperimentProtocolDriftingTextureV2BlockParameters < sln_symphony.ExperimentProtocol
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
