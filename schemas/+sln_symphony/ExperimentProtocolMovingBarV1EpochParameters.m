%{
#Epoch parameters for MovingBar (1) 
-> sln_symphony.ExperimentEpoch
---
bar_angle : float
protocol_version : float
%}
classdef ExperimentProtocolMovingBarV1EpochParameters < sln_symphony.ExperimentProtocol
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