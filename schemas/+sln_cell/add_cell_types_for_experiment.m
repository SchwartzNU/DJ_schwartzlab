function [] = add_cell_types_for_experiment(file_name)
cell_numbers = fetchn(aka.Cell & sprintf('file_name="%s"',file_name), 'cell_number');
N = length(cell_numbers);
cellNames = cell(N,1);
for i=1:N
    cellNames{i} = sprintf('%sc%d',file_name,cell_numbers(i));
end
sln_cell.add_cell_types_from_cellData(cellNames);