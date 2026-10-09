%{
#b parameters for CenterSurround (1) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : float
center_diameter : float
intensity_green : float
intensity_uv : float
mean_level : float
number_of_cycles : smallint unsigned
pre_time : float
rstar_mean : float
stim_time : float
surround_inner_diameter : float
surround_outer_diameter : float
tail_time : float
%}
classdef ExperimentProtCenterSurroundV1bp < sln_symphony.ExperimentProtocol
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
