%{
#b parameters for StepPulseScale (1) 
-> sln_symphony.ExperimentEpochBlock
---
output_amp_selection : smallint unsigned
pre_time: float
stim_time: float
tail_time: float
number_of_steps : tinyint unsigned
number_of_cycles: tinyint unsigned
scale_factor: float
%}
classdef ExperimentProtStepPulseScaleV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'protocol_version', 'min_stim_time', 'max_amplitude', 'random_ordering'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
