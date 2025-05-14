%{
#b parameters for PairedSpotField (2) 
-> sln_symphony.ExperimentEpochBlock
---
mean_level : float
num_repeats : smallint unsigned
num_spots_per_epoch : smallint unsigned
pre_time : float
rstar_mean : float
seed : int
spot_pre_frames : smallint unsigned
spot_size : float
spot_stim_frames : smallint unsigned
spot_tail_frames : smallint unsigned
tail_time : float
total_num_epochs : smallint unsigned
max_intensity : float
min_intensity : float
num_intensities : smallint unsigned
%}
classdef ExperimentProtPairedSpotFieldV2bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'antialias', 'spot_pre_time','spot_stim_time','spot_tail_time','stim_time','intensity'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
