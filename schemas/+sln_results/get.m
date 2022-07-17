function R = get(func_name,data_group,result_level,do_insert)
if nargin < 4
    do_insert = true;
end

R = table; %start empty

switch result_level
    case 'Experiment'
        items = sln_symphony.Experiment & data_group;
    case 'Animal'
        items = proj(sln_animal.Animal,'source_id->animal_source_id') & data_group;
    case 'Eye' %TODO;
        items = sln_animal.Eye & data_group;
    case 'Cell pair' %TODO, cell pair and eye levels
    case 'Cell'
        items = sln_symphony.ExperimentCell & data_group;
    case 'Dataset'
        items = aka.Dataset & data_group;
    case 'Epoch'
        items = sln_symphony.DatasetEpoch & data_group;
end

items_struct = fetch(items);
N_items = length(items_struct);
fprintf('%d items at level %s\n', N_items, result_level);

table_name = sprintf('%s%s',result_level,strrep(func_name,'_',''));
existing_results = eval(sprintf('sln_results.%s & items_struct', table_name));
fprintf('%d results found in %s\n', existing_results.count, table_name);
if existing_results.exists
    R = sln_results.toMatlabTable(existing_results);
    if ~do_insert
        R = removevars(R,{'user_name','git_tag','entry_time'});
    end
end

missing_results = items - existing_results;
if missing_results.exists
    fprintf('Running %s for %d remaining items of type %s\n', func_name, missing_results.count, result_level);
    Rnew = eval(sprintf('%s(missing_results);', func_name));
    if do_insert
        sln_results.insert(table,Rnew,result_level);
        R = eval(sprintf('sln_results.%s & items_struct', table_name));
    else
        R = [R; Rnew];
    end
end

