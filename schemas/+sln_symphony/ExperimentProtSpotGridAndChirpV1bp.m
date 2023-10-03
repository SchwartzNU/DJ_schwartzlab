%{
#b parameters for SpotGridAndChirp (1) 
-> sln_symphony.ExperimentEpochBlock
---
chirp_intensity : float
chirp_size : float
grid_x : float
grid_y : float
mean_level : float
number_of_chirps : smallint unsigned
number_of_grids : smallint unsigned
pre_time : float
rstar_mean : float
spot_count_in_x : float
spot_count_in_y : float
spot_intensity : float
spot_pre_frames : float
spot_size : float
spot_stim_frames : float
spot_tail_frames : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtSpotGridAndChirpV1bp < sln_symphony.ExperimentProtocol
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
