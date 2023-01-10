%{
#b parameters for TemporalFrequency (1) 
-> sln_symphony.ExperimentEpochBlock
---
background_pattern : float
contrast : float
max_frequency : float
mean_level : float
min_frequency : float
mstar_intensity : float
number_of_cycles : smallint unsigned
number_of_frequency_steps : smallint unsigned
pre_time : float
primary_object_pattern : float
rstar_mean : float
secondary_object_pattern : float
spot_size : float
sstar_intensity : float
stim_time : float
tail_time : float
wave_shape : varchar(64)
%}
classdef ExperimentProtTemporalFrequencyV1bp < sln_symphony.ExperimentProtocol
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
