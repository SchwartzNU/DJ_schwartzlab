%{
#Epoch parameters for LightStep (2) 
-> sln_symphony.ExperimentEpoch
---
protocol_version : float
current_spot_pattern : varchar(32)
%}
classdef ExperimentProtocolLightStepV2EpochParameters < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'current_spot_pattern'};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
