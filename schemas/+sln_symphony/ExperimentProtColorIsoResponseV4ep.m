%{
#Epoch parameters for ColorIsoResponse (4) 
-> sln_symphony.ExperimentEpoch
---
contrast_1 : float
contrast_2 : float
intensity_1 : float
intensity_2 : float
%}
classdef ExperimentProtColorIsoResponseV4ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'session_ID', 'stimulus_mode','protocol_version', 'fixed_pattern', 'fixed_contrast', 'ramp_ID'};
	end
	methods
        function epoch_key_new = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
            for i=1:length(epoch_key)
                ep = epoch_key(i);
                if ~isfield(ep,'contrast_1')
                     ep.contrast_1 = 0;
                end
                if ~isfield(ep,'contrast_2')
                     ep.contrast_2 = 0;
                end
                if isnan(ep.contrast_1)
                    ep.contrast_1 = 0;
                end
                if isnan(ep.contrast_2)
                    ep.contrast_2 = 0;
                end
                epoch_key_new(i) = ep;
            end

		%add entities to the key based on others
		end
	end
end
