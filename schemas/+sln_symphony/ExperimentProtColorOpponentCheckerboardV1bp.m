%{
#b parameters for ColorOpponentCheckerboard (1) 
-> sln_symphony.ExperimentEpochBlock
---
max_intensity_1 : float
max_intensity_2 : float
mean_level_1 : float
mean_level_2 : float
number_of_epochs : smallint unsigned
number_of_pixels : smallint unsigned
pixel_size : float
pre_time : float
stim_time : float
tail_time : float
texture_size : float
total_num_epochs : float
%}
classdef ExperimentProtColorOpponentCheckerboardV1bp < sln_symphony.ExperimentProtocol
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
