%{
#b parameters for NaturalMovingObject (1) 
-> sln_symphony.ExperimentEpochBlock
---
d : float
diameter : float
dt : float
dz : float
intensity : float
mean_level : float
motion_seed : int
motion_seed_change_mode : enum('repeat only', 'repeat & increment','increment only')
motion_trajectory : enum('natural','control')
num_repeats : smallint
num_seeds : smallint
omega_0 : float
pre_time : float
rfwidth : float
stim_time : float
tail_time : float
tau : float
tauz : float
%}
classdef ExperimentProtNaturalMovingObjectV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'antialias','rstar_mean'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
