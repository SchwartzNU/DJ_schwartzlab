%{
#b parameters for Ramp (2)
-> sln_symphony.ExperimentEpochBlock
---
number_of_repeats : smallint unsigned
output_amp_selection : smallint unsigned
pre_time : float
ramp_slope : tinyblob
random_ordering : enum('F','T') #bool
stim_time : float
tail_time : float
%}
% Ramp v2 (Symphony 3 port, 2026-10): rampSlope is a vector presented numberOfRepeats times,
% in pseudorandom order when randomOrdering is set; each epoch records currentRampSlope.
classdef ExperimentProtRampV2bp < sln_symphony.ExperimentProtocol
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
