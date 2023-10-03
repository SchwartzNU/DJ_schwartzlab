%{
#Block parameters for Chirp (2) 
-> sln_symphony.ExperimentEpochBlock
---
contrast_freq : float
contrast_max : float
contrast_min : float
contrast_total_time : float
freq_max : float
freq_min : float
freq_total_time : float
intensity : float
inter_time : float
mean_level : float
number_of_epochs : smallint unsigned
off_step_time : float
onstep_time : float
pre_time : float
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtChirpV2bp < sln_symphony.ExperimentProtocol
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
