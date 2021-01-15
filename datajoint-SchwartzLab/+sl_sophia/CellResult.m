%{
# Cell result stores computed information for a cell
-> sl.MeasuredCell     # cell this entry is for
-> sl.Pipeline  # analysis pipeline to which this result belongs
cell_func_name: varchar(64) #cell function used to generate result
---
result = NULL: longblob        # result structure
entry_time = CURRENT_TIMESTAMP : timestamp   # when this result was entered into db
param_struct = NULL: longblob  # struct of analysis parameters
%}

classdef CellResult < dj.Manual
    
end