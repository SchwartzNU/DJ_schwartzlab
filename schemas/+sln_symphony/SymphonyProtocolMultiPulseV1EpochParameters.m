%{
#Epoch parameters for MultiPulse (1) 
-> sln_symphony.SymphonyEpoch
---
curr_inter_time : float
pulse_1_curr : float
pulse_2_curr : float
%}
classdef SymphonyProtocolMultiPulseV1EpochParameters < sln_symphony.SymphonyProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'pulse_vector'};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
