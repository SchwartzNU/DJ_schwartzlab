%{
#b parameters for IsoResponseRamp (1) 
-> sln_symphony.ExperimentEpochBlock
---
exponent_base : float
exponential_mode : float
mean_level : float
num_ramps_per_epoch : float
number_of_epochs : smallint unsigned
off_pause_time : float
pre_time : float
ramp_points_intensity : tinyblob
ramp_points_time : tinyblob
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtIsoResponseRampV1bp < sln_symphony.ExperimentProtocol
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
