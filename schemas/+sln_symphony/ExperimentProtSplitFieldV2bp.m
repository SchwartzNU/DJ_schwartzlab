%{
#b parameters for SplitField (2) 
-> sln_symphony.ExperimentEpochBlock
---
angle_offset : float
bar_length : float
bar_separation : float
bar_width : float
contrast : float
mean_level : float
number_of_angles : smallint unsigned
number_of_cycles : smallint unsigned
number_of_positions : smallint unsigned
pre_time : float
rstar_mean : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtSplitFieldV2bp < sln_symphony.ExperimentProtocol
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
