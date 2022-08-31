function [] = insert_all_datasets_for_experiment(file_name)
CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
cellNames = ls([CELL_DATA_FOLDER filesep file_name '*.mat']);
if ispc
    cellNames = cellstr(cellNames);
else
    cellNames = strsplit(cellNames); %this will be different on windows - see doc ls
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

sln_cell.init_cells_from_ExperimentCells();
<<<<<<< HEAD
%sln_animal.updateGenotypeString();
=======
>>>>>>> 39a6e7c49d9987922f385c8c77b2e570e928eb76
sln_cell.add_cell_types_from_cellData(cellBaseNames);

