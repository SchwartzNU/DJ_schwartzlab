%{
#Block parameters for IvcUrve (3) 
-> sln_symphony.ExperimentEpochBlock
---
antialias : enum('F','T')
hold_signal_max : float
hold_signal_min : float
intensity : float
mean_level : float
number_of_amps_to_use : smallint unsigned
number_of_cycles : smallint unsigned
number_of_hold_signal_steps : smallint unsigned
pre_time : float
rstar_mean : float
spot_size : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtIvcUrveV3bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others


        t = {block_key(:).antialias};
            i = cellfun(@logical, t);
            [t{i}] = deal('T');
            [t{~i}] = deal('F');
            [block_key(:).antialias]  = t{:};
		end
	end
end
