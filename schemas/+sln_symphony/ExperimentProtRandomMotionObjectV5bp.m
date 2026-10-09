%{
#b parameters for RandomMotionObject (5) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : tinyint unsigned
intensity : float
mean_level : float
motion_lowpass_filter_passband : float
motion_lowpass_filter_stopband : float
motion_seed_change_mode : varchar(64)
motion_seed_start : float
motion_standard_deviation : float
number_of_epochs : smallint unsigned
pre_time : float
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
%}
% Staged by Symphony3\s3_djtables.m: no existing version accepted the file.
% Newest version mismatch: V4: block extra [antialias, motion_seed_change_mode, motion_seed_start, number_of_epochs] missing [motion_seed, number_of_cycles, seed]; epoch extra [] missing [seed]
classdef ExperimentProtRandomMotionObjectV5bp < sln_symphony.ExperimentProtocol
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
