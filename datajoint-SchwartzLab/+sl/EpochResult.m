%{
# Epoch result stores computed information for an epoch
-> sl.Epoch     # epoch this entry is for
-> sl.Pipeline  # analysis pipeline to which this result belongs
epoch_func_name: varchar(64) #epoch function used to generate result
---
result = NULL: longblob        # result structure
entry_time = CURRENT_TIMESTAMP : timestamp   # when this result was entered into db
param_struct = NULL: longblob  # struct of analysis parameters
%}

classdef EpochResult < dj.Manual
    
end