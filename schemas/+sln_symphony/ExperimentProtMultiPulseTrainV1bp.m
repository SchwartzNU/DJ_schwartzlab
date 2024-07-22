%{
#b parameters for MultiPulseTrain (1) 
-> sln_symphony.ExperimentEpochBlock
---
num_pulses : float
number_of_epochs : smallint unsigned
output_amp_selection : float
pre_time : float
pulse_amplitude : float
pulse_train_time : float
spike_train_pulse_time : float
st_num_pulses : float
stf_req : float
stim_time : float
tail_time : float
test_pulse_amplitude : float
test_pulse_time : float
%}
classdef ExperimentProtMultiPulseTrainV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'ptf_req', 'test_1_num_pulses', 'test_2_num_pulses'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
