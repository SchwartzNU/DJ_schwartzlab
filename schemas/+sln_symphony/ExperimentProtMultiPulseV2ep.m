%{
#Epoch parameters for MultiPulse (2) 
-> sln_symphony.ExperimentEpoch
---
pulse_1_curr : float
pulse_2_curr : float
%}
classdef ExperimentProtMultiPulseV2ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'pulse_vector', 'inter_time_vector', 'protocol_version'};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
