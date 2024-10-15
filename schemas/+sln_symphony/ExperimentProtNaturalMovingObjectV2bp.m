%{
#b parameters for NaturalMovingObject (2) 
-> sln_symphony.ExperimentEpochBlock
---
pre_frames : smallint unsigned
stim_frames : smallint unsigned
tail_frames : smallint unsigned
intensity : float
mean_level : float
tau : float
tauz : float
sigma : float
sigmaz : float
diameter : float
num_repeats : smallint unsigned
num_seeds : smallint unsigned
seed_start_value : int
mosaic_spacing : float
mosaic_degree : tinyint unsigned
motion_trajectory : enum('natural','control','natural+control')
pre_time : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtNaturalMovingObjectV2bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'antialias','rstar_mean','total_num_epochs','num_translations'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
