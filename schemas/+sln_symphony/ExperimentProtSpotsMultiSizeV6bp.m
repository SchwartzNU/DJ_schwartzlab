%{
# Block parameters for SpotsMultiSize (6)
-> sln_symphony.ExperimentEpochBlock
---
intensity                   : float                         # 
scaling                     : enum('log','linear','custom') # 
mean_level                  : float                         # 
number_of_cycles            : smallint unsigned             # 
pre_time                    : float                         # 
random_ordering             : enum('F','T')                 # bool
rstar_mean                  : float                         # 
stim_time                   : float                         # 
tail_time                   : float                         # 
do_subtraction : enum('F','T')
spot_sizes : tinyblob
%}
classdef ExperimentProtSpotsMultiSizeV6bp < sln_symphony.ExperimentProtocol
    properties

        %attributes to be renamed
        renamed_attributes = struct();

        %attributes to be removed from the key
        dropped_attributes = {};
    end
    methods
        function block_key_new = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
            %add entities to the key based on others
            for i=1:length(block_key)
                key = block_key(i);
                if isfield(key,'log_scaling')
                    if strcmp(key.log_scaling, 'T')
                        key.scaling = 'log';
                    else
                        key.scaling = 'linear';
                    end
                    key = rmfield(key, 'log_scaling');
                end

                if isfield(key,'pick_specific_sizes')
                    if key.pick_specific_sizes
                        key.scaling = 'custom';
                    end
                    key = rmfield(key, 'pick_specific_sizes');
                end

                if ~isfield(key, 'ramdom_ordering')
                    key.random_ordering = 'T';
                end
                block_key_new(i) = key;
            end
        end
    end
end
