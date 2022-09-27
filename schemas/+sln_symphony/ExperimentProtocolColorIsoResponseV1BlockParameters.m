%{
#Block parameters for ColorIsoResponse (1) 
-> sln_symphony.ExperimentEpochBlock
---
annulusMode : enum('true','false')
annulusInnerDiameter : float
annulusOuterDiameter : float
pre_time : float
rstar_mean : float
spot_diameter : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtocolColorIsoResponseV1BlockParameters < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'sessionId'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
