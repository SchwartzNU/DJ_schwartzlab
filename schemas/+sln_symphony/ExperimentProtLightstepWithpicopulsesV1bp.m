%{
#b parameters for LightstepWithpicopulses (1) 
-> sln_symphony.ExperimentEpochBlock
---
alternate_patterns : enum('F','T') #bool
antialias : float
intensity : float
mean_level : float
number_of_epochs : smallint unsigned
pre_time : float
pulse1_start : float
pulse2_start : float
pulse_dur : float
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtLightstepWithpicopulsesV1bp < sln_symphony.ExperimentProtocol
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
