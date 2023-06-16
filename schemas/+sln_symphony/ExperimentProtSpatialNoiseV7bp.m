%{
#b parameters for SpatialNoise (7) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : enum('F','T')
color_noise_mode : enum('1 pattern', '2 patterns')
color_noise_distribution : enum('gaussian', 'binary', 'uniform')
frame_dwell : smallint unsigned
number_of_epochs : smallint unsigned
pre_time : float
resolution_x : smallint unsigned
resolution_y : smallint unsigned
rstar_mean : float
seed_change_mode : enum('repeat only', 'repeat & increment', 'increment only')
seed_start_value : int unsigned
size_x : float
size_y : float
stim_time : float
tail_time : float
contrast_1 : float
contrast_2 : float
mean_level_1 : float
mean_level_2 : float
subsample_x: smallint unsigned
subsample_y : smallint unsigned
%}
classdef ExperimentProtSpatialNoiseV7bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'rfmemory', 'subsample_t', 'color_combination_mode', 'contrast', 'mean_level'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
            for i = 1:numel(block_key)
                if strcmp(block_key(i).color_noise_mode, '1 pattern')
                    block_key(i).contrast_1 = block_key(i).contrast;
                    block_key(i).mean_level_1 = block_key(i).mean_level;
                    block_key(i).contrast_2 = 0;
                    block_key(i).mean_level_2 = 0;   
                end
            end
		    %tobool
            t = {block_key(:).antialias};
            i = cellfun(@logical, t);
            [t{i}] = deal('T');
            [t{~i}] = deal('F');
            [block_key(:).antialias]  = t{:};
        end
	end
end
