%{
#b parameters for SpotFieldAndChirpAndBars (2) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : enum('F','T')
mean_level : float
rstar_mean : float

mstar_intensity_bar : float
rstar_intensity_bar : float
sstar_intensity_bar : float

bar_intensity : float
bar_led : tinyint unsigned
bar_length : float
bar_width : float

mstar_intensity_chirp : float
rstar_intensity_chirp : float
sstar_intensity_chirp : float

chirp_intensity : float
chirp_led : tinyint unsigned
chirp_size : float

mstar_intensity_spot : float
rstar_intensity_spot : float
sstar_intensity_spot : float

spot_intensity : float
spot_led : tinyint unsigned
spot_size : float
spot_pre_frames : float
spot_stim_frames : float
spot_tail_frames : float

coverage : float
extent_x : float
extent_y : float
grid_mode : enum('grid','random','rings')

number_of_bars : smallint unsigned
number_of_chirps : smallint unsigned
number_of_fields : smallint unsigned

pre_time : float
stim_time : float
tail_time : float

seed : float

%}
classdef ExperimentProtSpotFieldAndChirpAndBarsV2bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'protocol_version'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others


        t = {block_key(:).antialias};
            i = cellfun(@logical, t);
            [t{i}] = deal('T');
            [t{~i}] = deal('F');
            [block_key(:).antialias]  = t{:};
		end
	end
end
