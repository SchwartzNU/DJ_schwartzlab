function [queryResult, searchTable] = runPipelineQuery(queryEntry_struct)
if isempty(queryEntry_struct) || isempty(queryEntry_struct.query_state)
    queryResult = [];
    searchTable = [];
    return;
end
    
searchTable = makeSearchTable(queryEntry_struct.query_state.currentTables);
q = searchTable;
if strcmp(queryEntry_struct.use_query, 'T')
    q = eval(queryEntry_struct.query_str);
end
if strcmp(queryEntry_struct.use_cell_id_list, 'T')
    q = q & struct('cell_id', queryEntry_struct.cell_id_list);
end
if strcmp(queryEntry_struct.use_dataset_exclusion, 'T')
    excluded = sl_mutable.DatasetExcludeList & sprintf('pipeline_name="%s"', queryEntry_struct.pipeline_name);
    q = q - excluded;
end
if isfield(queryEntry_struct, 'use_epoch_filter') && strcmp(queryEntry_struct.use_epoch_filter, 'T') ...
    && isfield(queryEntry_struct, 'epoch_filter_func') && ~isempty(queryEntry_struct.epoch_filter_func)
   q = runEpochFilterFunction(queryEntry_struct.epoch_filter_func, q); 
end
    
queryResult = q;
