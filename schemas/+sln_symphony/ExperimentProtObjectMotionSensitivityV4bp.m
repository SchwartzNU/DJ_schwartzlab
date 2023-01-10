%{
#b parameters for ObjectMotionSensitivity (4) 
-> sln_symphony.ExperimentEpochBlock
---
center_diameter : float
contrast : float
figure_background_mode : varchar(64)
grating_profile : varchar(64)
intensity : float
mean_level : float
motion_angle : float
motion_lowpass_filter_passband : float
motion_seed_change_mode_center : varchar(64)
motion_seed_start : float
motion_standard_deviation : float
number_of_cycles : smallint unsigned
motion_include_differential : smallint unsigned
motion_include_global : smallint unsigned
motion_include_static : smallint unsigned
motion_include_surround : smallint unsigned
motion_path_mode : varchar(64)
pattern_mode : varchar(64)
pattern_spatial_scale : float
pre_time : float
rstar_mean : float
start_motion_time : float
stim_time : float
tail_time : float
motion_include_center : tinyint unsigned
annulus_thickness : float
motion_center_delay_frames : smallint unsigned
%}
classdef ExperimentProtObjectMotionSensitivityV4bp < sln_symphony.ExperimentProtocol
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
