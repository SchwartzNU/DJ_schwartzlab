%{
#b parameters for Uncaging (1) 
-> sln_symphony.ExperimentEpochBlock
---
drug_condition : varchar(64)
group_names : varchar(128)
laser_power : float
laser_wavelength : float
number_of_epochs : smallint unsigned
number_of_sequences : smallint unsigned
number_of_stim_groups : smallint unsigned
output_amp_selection : float
pre_time : float
pulse_amplitude : float
shutter_open : smallint unsigned  
stim_time : float
tail_time : float
%}
classdef ExperimentProtUncagingV1bp < sln_symphony.ExperimentProtocol
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
