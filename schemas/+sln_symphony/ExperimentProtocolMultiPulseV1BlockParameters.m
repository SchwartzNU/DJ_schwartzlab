%{
#Block parameters for MultiPulse (1) 
-> sln_symphony.ExperimentEpochBlock
---
inter_time : float
inter_time_amplitude : float
inter_time_opts : varchar(64)
log_scaling : enum('F','T') #bool
max_amplitude : float
max_inter_time : float
min_amplitude : float
min_inter_time : float
number_of_cycles : smallint unsigned
number_of_steps : smallint unsigned
(output_amp) -> sln_symphony.Channel(channel_name)
pre_time : float
pulse_1_amplitude : float
pulse_2_amplitude : float
random_ordering : enum('F','T') #bool
step_by_stim : enum('stim 1','stim 2','neither')
stim_1_time : float
stim_2_time : float
tail_time : float
%}
classdef ExperimentProtocolMultiPulseV1BlockParameters < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct('output_amp_selection','output_amp');

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
        %add entities to the key based on others
            %output amp
            output_amp = arrayfun(@(x) sprintf('Amp%d',x.output_amp_selection),block_key,'uni',0); 
            [block_key(:).output_amp_selection] = output_amp{:};
            
		end
	end
end
