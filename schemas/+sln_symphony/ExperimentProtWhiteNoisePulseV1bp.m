%{
#b parameters for WhiteNoisePulse (1) 
-> sln_symphony.ExperimentEpochBlock
---
output_amp_selection : smallint unsigned
pre_time: float
stim_time: float
tail_time: float
amplitude : float
std : float
frequency : float
number_of_epochs : tinyint unsigned
seed_start_value : smallint unsigned
seed_change_mode : enum('repeat only', 'repeat & increment', 'increment only')
%}
classdef ExperimentProtWhiteNoisePulseV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'protocol_version'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
