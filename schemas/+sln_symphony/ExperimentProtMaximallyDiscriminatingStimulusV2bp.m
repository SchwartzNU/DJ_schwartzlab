%{
#b parameters for MaximallyDiscriminatingStimulus (2) 
-> sln_symphony.ExperimentEpochBlock
---
movie_path : varchar(64)
number_of_epochs : smallint unsigned
rstar_mean : float
tail_time : float
total_num_epochs : float
ventral_up : float
%}
classdef ExperimentProtMaximallyDiscriminatingStimulusV2bp < sln_symphony.ExperimentProtocol
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
