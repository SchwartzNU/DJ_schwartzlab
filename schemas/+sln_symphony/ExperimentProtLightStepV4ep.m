%{
#Epoch parameters for LightStep (4) 
-> sln_symphony.ExperimentEpoch
---
protocol_version : float
%}
classdef ExperimentProtLightStepV4ep < sln_symphony.ExperimentProtocol
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
