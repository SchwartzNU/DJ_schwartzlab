%{
#b parameters for IsoResponseRamp (2) 
-> sln_symphony.ExperimentEpochBlock
---
exponential_mode : float
exponential_polarity : smallint
time_constant : float
mean_level : float
number_of_epochs : smallint unsigned
pre_time : float
ramp_points_intensity : tinyblob
ramp_points_time : tinyblob
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtIsoResponseRampV2bp < sln_symphony.ExperimentProtocol
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
