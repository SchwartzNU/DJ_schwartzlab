%{
#e parameters for ObjectMotionSensitivity (2) 
-> sln_symphony.ExperimentEpoch
---
motion_mode : varchar(32)
motion_seed_center : float
motion_seed_surround : float
protocol_version : float
%}
classdef ExperimentProtObjectMotionSensitivityV2ep < sln_symphony.ExperimentProtocol
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
