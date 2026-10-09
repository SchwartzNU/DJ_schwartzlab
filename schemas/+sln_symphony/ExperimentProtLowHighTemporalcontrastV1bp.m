%{
#b parameters for LowHighTemporalcontrast (1) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : float
aperture : float
color_noise_distribution : varchar(64)
color_noise_mode : varchar(64)
frame_dwell : float
high_contrast : float
low_contrast : float
mean_level : float
number_of_epochs : smallint unsigned
pre_time : float
rstar_mean : float
seed_change_mode : varchar(64)
seed_start_value : float
spot_mean_level : float
stim_time : float
switch_time : float
tail_time : float
%}
classdef ExperimentProtLowHighTemporalcontrastV1bp < sln_symphony.ExperimentProtocol
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
