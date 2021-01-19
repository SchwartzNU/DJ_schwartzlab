%{
# PipelineQuery stores the single loading query for each analysis pipeline
-> sl.Pipeline
---
query_str = NULL: varchar(1024) #query string
epoch_filter_func = NULL: varchar(64) #name of epoch filtering function if it has one
query_state = NULL : longblob  #struct with full queryState including the tables in queryState.currentTables
cell_id_list = NULL: longblob #cell array of cellIDs to use in restriction
use_query : enum('T', 'F') #use query to restrict
use_cell_id_list : enum('T', 'F') #use cell_id list to restrict
use_epoch_filter : enum('T', 'F') #use epoch filter to restrict
use_dataset_exclusion : enum('T', 'F') #use dataset exclusion table in restriction
%}

classdef PipelineQuery < dj.Manual
    
end
