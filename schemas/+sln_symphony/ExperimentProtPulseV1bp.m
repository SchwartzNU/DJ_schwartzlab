%{
#Block parameters for Pulse (1) 
-> sln_symphony.ExperimentEpochBlock
---
number_of_epochs : smallint unsigned
(output_amp) -> sln_symphony.Channel(channel_name)
pre_time : float
pulse_amplitude : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtPulseV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct('output_amp_selection','output_amp');

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
            %ouptut amp
            output_amp = arrayfun(@(x) sprintf('Amp%d',x.output_amp_selection),block_key,'uni',0); 
            [block_key(:).output_amp_selection] = output_amp{:};
		end
	end
end
