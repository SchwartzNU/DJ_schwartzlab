%{
#e parameters for PairedBars (1) 
-> sln_symphony.ExperimentEpoch
---
bar_1_position : float
bar_2_position : float
bar_angle : float
delay : float
%}
classdef ExperimentProtPairedBarsV1ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'protocol_version'};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
