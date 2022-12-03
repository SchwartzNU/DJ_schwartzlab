%{
#Block parameters for LightStep (2) 
-> sln_symphony.ExperimentEpochBlock
---
alternate_patterns : enum('F','T') #bool
intensity : float
mean_level : float
number_of_epochs : smallint unsigned
pre_time : float
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
imaging_field_height : float
imaging_field_width : float
imaging_mean: float
rstar_midground: float
do_subtraction : enum('F','T') #bool
%}
classdef ExperimentProtocolLightStepV2BlockParameters < sln_symphony.ExperimentProtocol
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
