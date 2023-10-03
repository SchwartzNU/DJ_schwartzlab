%{
#e parameters for TextureMatrix (2) 
-> sln_symphony.ExperimentEpoch
---
texture_scale : float
negative_image : float
protocol_version : float
random_seed : float
%}
classdef ExperimentProtTextureMatrixV2ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
