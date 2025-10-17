%{
#b parameters for OptopulseTrain (1) 
-> sln_symphony.ExperimentEpochBlock
---
downtime : float
num_pulses : float
number_of_epochs : smallint unsigned
pre_time : float
pulse_time : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtOptopulseTrainV1bp < sln_symphony.ExperimentProtocol
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
