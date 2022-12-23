%{
#e parameters for IsoResponseRamp (2) 
-> sln_symphony.ExperimentEpoch
---
epoch_index : float
protocol_version : float
ramp_points_intensity : tinyblob
ramp_points_time : tinyblob
%}
classdef ExperimentProtIsoResponseRampV2ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'time_constant'};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
