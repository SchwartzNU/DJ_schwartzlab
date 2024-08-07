%{
#Block parameters for HexSms (1) 
-> sln_symphony.ExperimentEpochBlock
---
coverage : float
grid_x : float
grid_y : float
intensity : float
log_scaling : enum('F','T') #bool
max_size : float
mean_level : float
min_size : float
number_of_cycles : smallint unsigned
number_of_size_steps : smallint unsigned
pre_time : float
random_ordering : enum('F','T') #bool
rstar_mean : float
stim_time : float
tail_time : float
time_estimate : float
total_num_epochs : float
%}
classdef ExperimentProtHexSmsV1bp < sln_symphony.ExperimentProtocol
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
