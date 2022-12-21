%{
#Block parameters for ContrastResponse (3) 
-> sln_symphony.ExperimentEpochBlock
---
contrast_direction : varchar(64)
max_contrast : float
mean_level : float
min_contrast : float
number_of_contrast_steps : smallint unsigned
number_of_cycles : smallint unsigned
pre_time : float
real_number_of_contrast_steps : smallint unsigned
rstar_mean : float
shape : varchar(64)
spot_diameter : float
stim_time : float
tail_time : float
uniform_xy : float
do_subtraction : enum('T', 'F')
%}
classdef ExperimentProtContrastResponseV3bp < sln_symphony.ExperimentProtocol
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
