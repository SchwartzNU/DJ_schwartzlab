%{
# Result accross cells/datasets/epochs/etc
-> sl.Pipeline  # analysis pipeline to which this result belongs
func_name: varchar(64) #function used to generate result
---
entry_time = CURRENT_TIMESTAMP : timestamp   # when this result was entered into db
param_struct = NULL: longblob  # struct of analysis parameters
%}

classdef Result < dj.Manual
    
end