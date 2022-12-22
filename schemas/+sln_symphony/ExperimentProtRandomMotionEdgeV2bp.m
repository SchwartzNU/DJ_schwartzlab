%{
# b parameters for RandomMotionEdge (2)
-> sln_symphony.ExperimentEpochBlock
---
angle_offset                : float                         # 
bar_length                  : float                         # 
bar_width                   : float                         # 
intensity                   : float                         # 
mean_level                  : float                         # 
motion_lowpass_filter_passband: float                       # 
motion_lowpass_filter_stopband: float                       # 
motion_seed                 : float                         # 
motion_standard_deviation   : float                         # 
number_of_angles            : smallint unsigned             # 
number_of_cycles            : smallint unsigned             # 
pre_time                    : float                         # 
rstar_mean                  : float                         # 
stim_time                   : float                         # 
tail_time                   : float                         # 
single_edge_mode            : smallint unsigned             # 
single_edge_polarity        : smallint             # 
%}
classdef ExperimentProtRandomMotionEdgeV2bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'random_seed'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
