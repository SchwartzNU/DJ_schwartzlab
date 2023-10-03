%{
#b parameters for Ramp (1) 
-> sln_symphony.ExperimentEpochBlock
---
output_amp_selection : smallint unsigned
ramp_slope : float
pre_time: float
stim_time: float
tail_time: float
%}
classdef ExperimentProtRampV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'number_of_epochs'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
