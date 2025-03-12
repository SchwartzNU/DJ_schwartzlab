%{
#b parameters for WhiteToPinkNoisePulse (1) 
-> sln_symphony.ExperimentEpochBlock
---
amplitude : float
frequency : float
number_of_epochs_per_beta : smallint unsigned
output_amp_selection : float
pre_time : float
seed_change_mode : enum('repeat only', 'repeat & increment', 'increment only')
seed_start_value : float
std : float
stim_time : float
tail_time : float
total_num_epochs : float
%}
classdef ExperimentProtWhiteToPinkNoisePulseV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'betas'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
