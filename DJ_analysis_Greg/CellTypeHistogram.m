function S = CellTypeHistogram(data_group)
cell_types = fetchn(sln_cell.Cell * sln_cell.AssignType.current & proj(data_group), 'cell_type');
unique_types = unique(cell_types);
N = length(unique_types);

S.cell_types = cell(N,1);
S.count = zeros(N,1);
S.fraction = cell(N,1);

for i=1:N
    S.cell_types{i} = unique_types{i};
    S.count(i) = sum(strcmp(cell_types,unique_types{i}));    
end

S.N_cells = sum(S.count);

S.fraction = S.count / S.N_cells;


