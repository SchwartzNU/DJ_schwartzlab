%{
# Dataset result stores computed information for a dataset
-> sl.Dataset     # dataset this entry is for
-> sl.Pipeline  # analysis pipeline to which this result belongs
dataset_func_name: varchar(64) #dataset function used to generate result
---
entry_time = CURRENT_TIMESTAMP : timestamp   # when this result was entered into db
param_struct = NULL: longblob  # struct of analysis parameters
%}

classdef DatasetResult < dj.Manual
    
end