%{
#e parameters for ObjectMotionSensitivity (4) 
-> sln_symphony.ExperimentEpoch
---
motion_mode : varchar(32)
motion_seed_center : float
motion_seed_surround : float
protocol_version : float
%}
classdef ExperimentProtObjectMotionSensitivityV4ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
    end
    methods
        function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
            for i=1:length(epoch_key)
                epoch_key(i).motion_mode = num2str(epoch_key(i).motion_mode);
            end
    		%add entities to the key based on others
        end
	end
end
