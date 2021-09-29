%{
#Block parameters for SpotsMultiSize (1) 
-> sln_symphony.SymphonyEpochBlock
---
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
%}
classdef SymphonyProtocolSpotsMultiSizeV1BlockParameters < sln_symphony.SymphonyProtocol
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
