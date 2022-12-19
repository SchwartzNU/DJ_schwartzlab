%{
#Block parameters for SpatialNoise (1) 
-> sln_symphony.ExperimentEpochBlock
---
blue_blanking : float
color_noise_mode : varchar(64)
contrast : float
do_subtraction : enum('F','T') #bool
frame_dwell : float
green_blanking : float
imaging_field_height : float
imaging_field_width : float
imaging_mean : float
max_offset : float
mean_level : float
number_of_epochs : smallint unsigned
offset_delta : float
pre_time : float
resolution_x : float
resolution_y : float
rstar_mean : float
rstar_midground : float
seed_change_mode : varchar(64)
seed_start_value : float
size_x : float
size_y : float
stim_time : float
tail_time : float
uv_blanking : float
%}
classdef ExperimentProtSpatialNoiseV1bp < sln_symphony.ExperimentProtocol
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
