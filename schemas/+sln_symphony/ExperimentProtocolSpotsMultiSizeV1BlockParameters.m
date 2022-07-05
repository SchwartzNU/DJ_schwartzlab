%{
#Block parameters for SpotsMultiSize (1) 
-> sln_symphony.ExperimentEpochBlock
---
intensity : float
scaling : enum('log','linear','custom')
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
%}
classdef ExperimentProtocolSpotsMultiSizeV1BlockParameters < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'pick_specific_sizes','spot_sizes','log_scaling'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others

		%TODO: test this!!!
		log_scaled = cellfun(@(x) strcmp(x,'T'), {block_key(:).log_scaling});
		[block_key(~log_scaled).scaling] = deal('linear');
		[block_key(log_scaled).scaling] = deal('log');
		if isfield(block_key,'pick_specific_sizes')

			pick_sizes = logical([block_key(:).pick_specific_sizes]);

			[block_key(pick_sizes).scaling] = deal('custom');
		end
			
		end
	end
end
