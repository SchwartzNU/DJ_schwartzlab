%{
#e parameters for ColorResponse (1) 
-> sln_symphony.ExperimentEpoch
---
intensity_1 : float
intensity_2 : float
protocol_version : float
sort_colors : float
%}
classdef ExperimentProtColorResponseV1ep < sln_symphony.ExperimentProtocol
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
