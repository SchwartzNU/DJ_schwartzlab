%{
#Block parameters for ReceptiveField1D (1) 
-> sln_symphony.ExperimentEpochBlock
---
bar_length : float
bar_separation : float
bar_width : float
contrast : float
frequency : float
mean_level : float
number_of_contrast_pulses : smallint unsigned
number_of_cycles : smallint unsigned
number_of_positions : smallint unsigned
pre_time : float
probe_axis : varchar(64)
rstar_mean : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtocolReceptiveField1DV1BlockParameters < sln_symphony.ExperimentProtocol
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
