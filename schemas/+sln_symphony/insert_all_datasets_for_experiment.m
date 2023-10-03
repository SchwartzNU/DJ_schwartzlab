function [] = insert_all_datasets_for_experiment(file_name)
CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
D = dir([CELL_DATA_FOLDER filesep file_name '*.mat']);
if isempty(D)
    disp('No local cellData files found. Copying from CellDataMaster.');
    CELL_DATA_MASTER = [getenv('SERVER') filesep 'CellDataMaster'];
    copyfile([CELL_DATA_MASTER filesep file_name '*.mat'], CELL_DATA_FOLDER)
end

cellNames = ls([CELL_DATA_FOLDER filesep file_name '*.mat']);
if ispc
    cellNames = cellstr(cellNames)
else
    cellNames = strsplit(cellNames);  %this will be different on windows - see doc ls
end

cellBaseNames = cell(length(cellNames), 1);
for i=1:length(cellNames)
    [~, basename, ~] = fileparts(cellNames{i});
    cellBaseNames{i} = basename;
end

for i=1:length(cellBaseNames)
    if ~isempty(cellBaseNames{i})
        fprintf('inserting datasets for cell %s\n', cellBaseNames{i});
        insert(sln_symphony.Dataset,cellBaseNames{i});
    end
end

% insert cells for ExperimentCells
exp_cells = sln_symphony.ExperimentCell * ...
    proj(sln_symphony.ExperimentRetina,'*','source_id->retina_id') * ...
    proj(sln_animal.Animal,'*','source_id->animal_source_id') & ...
    sprintf('file_name="%s"', file_name);
exp_cells_to_insert = exp_cells - sln_cell.Cell;
exp_cells_struct = rmfield(fetch(exp_cells_to_insert),'retina_id');
%insert(sln_cell.Cell,exp_cells_struct,'REPLACE');

insert(sln_cell.Cell,exp_cells_struct)

%sln_cell.init_cells_from_ExperimentCells();
sln_cell.add_cell_types_from_cellData(cellBaseNames);

%get user params and insert nulls
[data_levels, user_params_table_names] = sln_symphony.get_all_user_param_in_db;
s = fetch(exp_cells);
for i = 1:length(data_levels)
    table_name = sprintf('sln_symphony.UserParam%s%s', data_levels{i}, user_params_table_names{i});
    
    switch data_levels{i}
        case 'Experiment'
            s_for_insert = rmfield(s, {'animal_id', 'source_id', 'retina_id'});
            
        case 'Animal'
            s_for_insert = rmfield(s, {'file_name', 'source_id', 'retina_id'});
            
        case 'Cell'
            s_for_insert = rmfield(s, {'animal_id', 'retina_id'});
            
        case 'Dataset'
            unlabeled_items = fetch(sln_symphony.Dataset * exp_cells);
            s_for_insert = rmfield(unlabeled_items, {'retina_id', 'animal_id'});
            
        case 'Epoch'
            unlabeled_items = fetch(aka.Epoch * exp_cells);
            s_for_insert = rmfield(unlabeled_items, {'retina_id', 'animal_id'});
        
    end
    insert(eval(table_name),s_for_insert,'IGNORE');
end
