%{
#Epoch parameters for SpotsMultiSize (9) 
-> sln_symphony.ExperimentEpoch
---
cur_spot_size : float
protocol_version : float
%}
classdef ExperimentProtSpotsMultiSizeV9ep < sln_symphony.ExperimentProtocol
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
