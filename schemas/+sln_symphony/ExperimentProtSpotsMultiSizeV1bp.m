%{
# Block parameters for SpotsMultiSize (1)
-> sln_symphony.ExperimentEpochBlock
---
intensity                   : float                         # 
scaling                     : enum('log','linear','custom') # 
max_size                    : float                         # 
mean_level                  : float                         # 
min_size                    : float                         # 
number_of_cycles            : smallint unsigned             # 
number_of_size_steps        : smallint unsigned             # 
pre_time                    : float                         # 
random_ordering             : enum('F','T')                 # bool
rstar_mean                  : float                         # 
stim_time                   : float                         # 
tail_time                   : float                         # 
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
            if isfield(block_key,'log_scaling')
                keyboard;
                if block_key.log_scaling
                    block_key.scaling = 'log';
                else
                    block_key.scaling = 'linear';
                end
                block_key = rmfield(block_key, 'log_scaling');
            end

            if isfield(block_key,'pick_specific_sizes')
                if block_key.pick_specific_sizes
                    block_key.scaling = 'custom';
                end
                block_key = rmfield(block_key, 'pick_specific_sizes');
            end
        end
    end
end
