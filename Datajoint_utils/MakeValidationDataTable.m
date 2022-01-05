function T = MakeValidationDataTable(q)
allTypes = fetchn(q,'cell_type');
N = length(allTypes);

typesU = unique(allTypes);
Ntypes = length(typesU);

T = table('Size',[Ntypes, 11], ...
    'VariableTypes',{'string', 'uint16', 'uint16', 'double', 'uint16', 'uint16', ...
    'uint16', 'uint16','uint16', 'uint16', 'uint16'}, ...
    'VariableNames', {'RGC_type', 'N_phys', 'N_validated', 'Percent_validated', 'N_confocal', 'N_2P', ...
    'Trangenic_validation_N', 'Whole_cell_validation_N','Soma_size_validation_N','DS_validation_N','OS_validation_N'});

q_struct = fetch(q);

for i=1:Ntypes
    curType = typesU{i};
    ind = strcmp(allTypes,curType);
    
    T(i,'RGC_type') = {curType};
    T(i,'N_phys') = {sum(ind)};
    
    query_2P = sl_mutable.RGCValidationData & q_struct(ind) & 'validation_data_type = "2P image"' & 'score = "medium" OR score = "high"';
    query_confocal = sl_mutable.RGCValidationData & q_struct(ind) & 'validation_data_type = "confocal image"' & 'score = "medium" OR score = "high"';
    query_soma = sl_mutable.RGCValidationData & q_struct(ind) & 'validation_data_type = "soma size"';
    query_DS = sl_mutable.RGCValidationData & q_struct(ind) & 'validation_data_type = "direction selectivity"';
    query_OS = sl_mutable.RGCValidationData & q_struct(ind) & 'validation_data_type = "orientation selectivity"';
    query_transgenic = sl_mutable.RGCValidationData & q_struct(ind) & 'validation_data_type = "transgenic line"' & 'score != "low"';
    query_wc = sl_mutable.RGCValidationData & q_struct(ind) & 'validation_data_type = "whole-cell recording"' & 'score != "low"';
    
    ids_2P = [];
    ids_confocal = [];
    ids_soma = [];
    ids_DS = [];
    ids_OS = [];
    ids_transgenic = [];
    ids_wc = [];
    
    if query_2P.exists, ids_2P = fetchn(query_2P,'cell_unid'); end
    if query_confocal.exists, ids_confocal = fetchn(query_confocal,'cell_unid'); end
    if query_soma.exists, ids_soma = fetchn(query_soma,'cell_unid'); end
    if query_DS.exists, ids_DS = fetchn(query_DS,'cell_unid'); end
    if query_OS.exists, ids_OS = fetchn(query_OS,'cell_unid'); end
    if query_transgenic.exists, ids_transgenic = fetchn(query_transgenic,'cell_unid'); end
    if query_wc.exists, ids_wc = fetchn(query_wc,'cell_unid'); end
    
    %TODO - add image data here when it is scored
    all_ids = unique([ids_2P; ids_confocal; ids_soma; ids_DS; ids_OS; ids_transgenic; ids_wc]);
    T(i,'N_validated') = {length(all_ids)};
    T(i,'Percent_validated') = {100 * length(all_ids) / sum(ind)};
    
    T(i,'N_2P') = {query_2P.count};
    T(i,'N_confocal') = {query_confocal.count};
    T(i,'Trangenic_validation_N') = {query_transgenic.count};
    T(i,'Whole_cell_validation_N') = {query_wc.count};
    T(i,'Soma_size_validation_N') = {query_soma.count};
    T(i,'DS_validation_N') = {query_DS.count};
    T(i,'OS_validation_N') = {query_OS.count};
    
end
