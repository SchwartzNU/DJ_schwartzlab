%{
#Epoch parameters for ContrastResponse (1) 
-> sln_symphony.SymphonyEpoch
---
contrast : float
intensity : float
%}
classdef SymphonyProtocolContrastResponseV1EpochParameters < sln_symphony.SymphonyProtocol
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
