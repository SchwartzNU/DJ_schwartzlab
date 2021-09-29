%{
#Epoch parameters for FlashedBar (1) 
-> sln_symphony.SymphonyEpoch
---
bar_angle : float
protocol_version : float
%}
classdef SymphonyProtocolFlashedBarV1EpochParameters < sln_symphony.SymphonyProtocol
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
