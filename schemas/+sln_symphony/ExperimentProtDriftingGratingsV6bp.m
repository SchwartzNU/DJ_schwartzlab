%{
# Block parameters for DriftingGratings (6)
-> sln_symphony.ExperimentEpochBlock
---
aperture_diameter           : float                         # 
contrast                    : float                         # 
cycle_half_width            : float                         # 
grating_length              : float                         # 
grating_profile             : varchar(64)                   # 
grating_speed               : float                         # 
grating_width               : float                         # 
mean_level                  : float                         # 
movement_delay              : float                         # 
number_of_angles            : smallint unsigned             # 
number_of_cycles            : smallint unsigned             # 
pre_time                    : float                         # 
rstar_mean                  : float                         # 
spatial_freq                : float                         # 
stim_time                   : float                         # 
tail_time                   : float                         # 
temporal_freq               : float                         # 
total_num_epochs            : float                         # 
background_pattern : tinyint unsigned
mstar_intensity : float
primary_object_pattern : tinyint unsigned
secondary_object_pattern : tinyint unsigned
sstar_intensity : float
color_combination_mode: varchar(32)
%}
classdef ExperimentProtDriftingGratingsV6bp < sln_symphony.ExperimentProtocol
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
