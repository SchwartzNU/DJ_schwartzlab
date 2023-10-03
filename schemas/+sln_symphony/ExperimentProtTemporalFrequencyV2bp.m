%{
#b parameters for TemporalFrequency (2) 
-> sln_symphony.ExperimentEpochBlock
---
contrast : float
max_frequency : float
mean_level : float
min_frequency : float
number_of_cycles : smallint unsigned
number_of_frequency_steps : smallint unsigned
pre_time : float
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
wave_shape : varchar(64)
%}
classdef ExperimentProtTemporalFrequencyV2bp < sln_symphony.ExperimentProtocol
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
