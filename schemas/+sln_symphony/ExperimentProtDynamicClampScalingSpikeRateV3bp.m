%{
#b parameters for DynamicClampScalingSpikeRate (3) 
-> sln_symphony.ExperimentEpochBlock
---
amp : float
exc_conductances_file : varchar(64)
g_exc_multiplier : float
g_inh_multiplier : float
inh_conductances_file : varchar(64)
number_of_averages : smallint unsigned
pre_time : float
stim_time : float
tail_time : float
exc_reversal : float
inh_reversal : float
n_sp_er_volt : float
%}
classdef ExperimentProtDynamicClampScalingSpikeRateV3bp < sln_symphony.ExperimentProtocol
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
