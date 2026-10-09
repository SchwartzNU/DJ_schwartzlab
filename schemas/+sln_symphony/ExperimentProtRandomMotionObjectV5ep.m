%{
#e parameters for RandomMotionObject (5) 
-> sln_symphony.ExperimentEpoch
---
motion_seed : float
protocol_version : float
%}
% Staged by Symphony3\s3_djtables.m: no existing version accepted the file.
% Newest version mismatch: V4: block extra [antialias, motion_seed_change_mode, motion_seed_start, number_of_epochs] missing [motion_seed, number_of_cycles, seed]; epoch extra [] missing [seed]
classdef ExperimentProtRandomMotionObjectV5ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
