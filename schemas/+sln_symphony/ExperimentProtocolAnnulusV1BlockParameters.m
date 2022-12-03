%{
#Block parameters for Annulus (1) 
-> sln_symphony.ExperimentEpochBlock
---
init_area : float
init_thick : float
intensity : float
keep_constant : varchar(64)
max_inner_diam : float
max_outer_diam : float
mean_level : float
min_inner_diam : float
min_outer_diam : float
number_of_cycles : smallint unsigned
number_of_size_steps : smallint unsigned
pre_time : float
rstar_mean : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtocolAnnulusV1BlockParameters < sln_symphony.ExperimentProtocol
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
