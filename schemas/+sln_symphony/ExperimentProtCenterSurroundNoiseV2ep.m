%{
#e parameters for CenterSurroundNoise (2) 
-> sln_symphony.ExperimentEpoch
---
center_noise_seed : float
current_stimulus : varchar(64)
protocol_version : float
surround_noise_seed : float
%}
classdef ExperimentProtCenterSurroundNoiseV2ep < sln_symphony.ExperimentProtocol
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
