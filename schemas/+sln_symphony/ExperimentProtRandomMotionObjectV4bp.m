%{
#b parameters for RandomMotionObject (4) 
-> sln_symphony.ExperimentEpochBlock
---
intensity : float
mean_level : float
motion_seed : smallint
seed : smallint
motion_lowpass_filter_passband : float
motion_lowpass_filter_stopband : float
motion_standard_deviation : float
number_of_cycles : smallint unsigned
pre_time : float
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtRandomMotionObjectV4bp < sln_symphony.ExperimentProtocol
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
