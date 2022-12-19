%{
#Block parameters for SpotsMultiSize (1) 
-> sln_symphony.ExperimentEpochBlock
---
intensity : float
log_scaling : enum('F','T') #bool
max_size : float
mean_level : float
min_size : float
number_of_cycles : smallint unsigned
number_of_size_steps : smallint unsigned
pick_specific_sizes : float
pre_time : float
random_ordering : enum('F','T') #bool
rstar_mean : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtSpotsMultiSizeV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
            if isfield(block_key,'scaling')
                block_key
                keyboard;
                if strcmp(block_key.scaling,'log')
                    block_key.log_scaling = 'T';
                else
                    block_key.log_scaling = 'F';
                end
                if strcmp(block_key.scaling,'custom')
                    block_key.pick_specific_sizes = 'T';
                else
                    block_key.pick_specific_sizes = 'F';
                end
            end
		end
	end
end
