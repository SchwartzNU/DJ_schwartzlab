%{
#Epoch parameters for DriftingGratings (4) 
-> sln_symphony.ExperimentEpoch
---
angles_like_moving_bar : float
grating_angle : float
protocol_version : float
%}
classdef ExperimentProtDriftingGratingsV4ep < sln_symphony.ExperimentProtocol
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
