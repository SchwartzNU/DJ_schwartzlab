%{
#b parameters for OffsetMovingBar (1) 
-> sln_symphony.ExperimentEpochBlock
---
angle_offset : float
bar_length : float
bar_speed : float
distance : float
intensity : float
mean_level : float
number_of_angles : smallint unsigned
number_of_cycles : smallint unsigned
number_of_offsets : smallint unsigned
offset_range : tinyblob
offset_side : varchar(64)
pre_time : float
rstar_mean : float
single_edge_mode : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtOffsetMovingBarV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'angles'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
