%{
#e parameters for TextureNoise (1) 
-> sln_symphony.ExperimentEpoch
---
noise_seed : int
%}
classdef ExperimentProtTextureNoiseV1ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'protocol_version'};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
