%{
#Epoch parameters for HexSms (2) 
-> sln_symphony.ExperimentEpoch
---
cur_spot_size : float
cx : float
cy : float
protocol_version : float
%}
classdef ExperimentProtocolHexSmsV2EpochParameters < sln_symphony.ExperimentProtocol
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
