%{
#Epoch parameters for ColorIsoResponse (1) 
-> sln_symphony.ExperimentEpoch
---
contrast_1 : float
contrast_2 : float
intensity_1 : float
intensity_2 : float
%}
classdef ExperimentProtColorIsoResponseV1ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'session_ID', 'stimulus_mode'};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
