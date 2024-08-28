%{
#b parameters for PairedBars (1) 
-> sln_symphony.ExperimentEpochBlock
---
bar_duration : float
bar_length : float
bar_width : float
delay_increment : float
intensity : float
mean_level : float
number_of_angles : smallint unsigned
number_of_cycles : smallint unsigned
number_of_delays : smallint unsigned
number_of_positions : smallint unsigned
paired : enum('F','T')
phase : float
pre_time : float
rstar_mean : float
spacing_increment : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtPairedBarsV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'antialias'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others

            t = {block_key(:).paired};
            i = cellfun(@logical, t);
            [t{i}] = deal('T');
            [t{~i}] = deal('F');
            [block_key(:).paired]  = t{:};
		end
	end
end
