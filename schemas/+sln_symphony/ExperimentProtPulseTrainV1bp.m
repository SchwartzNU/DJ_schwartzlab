%{
#b parameters for PulseTrain (1) 
-> sln_symphony.ExperimentEpochBlock
---
num_pulses : float
number_of_epochs : smallint unsigned
output_amp_selection : float
pre_time : float
pulse_amplitude : float
pulse_time : float
stim_time : float
tail_time : float
train_freq : float
%}
classdef ExperimentProtPulseTrainV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
