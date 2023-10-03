%{
#b parameters for MaximallyExcitatoryInputs (1) 
-> sln_symphony.ExperimentEpochBlock
---
color_combination_mode : varchar(64)
contrast_1 : float
contrast_2 : float
mean_level_1 : float
mean_level_2 : float
number_of_repetitions : smallint unsigned
pre_time : float
random_ordering : enum('F','T') #bool
rstar_mean : float
stim_time : float
tail_time : float
total_num_epochs : float
ventral_up : float
%}
classdef ExperimentProtMaximallyExcitatoryInputsV1bp < sln_symphony.ExperimentProtocol
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
