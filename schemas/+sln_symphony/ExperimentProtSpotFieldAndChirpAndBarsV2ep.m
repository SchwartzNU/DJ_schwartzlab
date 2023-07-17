%{
#e parameters for SpotFieldAndChirpAndBars (2) 
-> sln_symphony.ExperimentEpoch
---
trial_type : enum('bars','chirp','field')
cx = NULL : blob
cy = NULL  : blob
theta = NULL  : blob
%}
classdef ExperimentProtSpotFieldAndChirpAndBarsV2ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'protocol_version'};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
        if ~isfield(epoch_key,'theta')
            [epoch_key(:).theta] = deal(nan);
        end

		end
	end
end
