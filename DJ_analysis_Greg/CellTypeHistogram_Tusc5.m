function S = CellTypeHistogram_Tusc5(data_group)
data_group_with_genotypes = data_group * sln_animal.GenotypeString;
homo_part = data_group_with_genotypes & 'genotype_string LIKE "%Tusc5-eGFP/Tusc5-eGFP%"';
het_part = data_group_with_genotypes - proj(homo_part);

cell_types = fetchn(sln_cell.Cell * sln_cell.AssignType.current & proj(data_group), 'cell_type');
cell_types_homo = fetchn(sln_cell.Cell * sln_cell.AssignType.current & proj(homo_part), 'cell_type');
cell_types_het = fetchn(sln_cell.Cell * sln_cell.AssignType.current & proj(het_part), 'cell_type');

unique_types = unique(cell_types);
N = length(unique_types);

S.cell_types = cell(N,1);
S.count = zeros(N,1);
S.fraction = cell(N,1);
S.count_homo = zeros(N,1);
S.fraction_homo = cell(N,1);
S.count_het = zeros(N,1);
S.fraction_het = cell(N,1);

for i=1:N
    S.cell_types{i} = unique_types{i};
    S.count(i) = sum(strcmp(cell_types,unique_types{i}));    
    S.count_homo(i) = sum(strcmp(cell_types_homo,unique_types{i})); 
    S.count_het(i) = sum(strcmp(cell_types_het,unique_types{i})); 
end

S.N_cells = sum(S.count);
S.N_cells_homo = sum(S.count_homo);
S.N_cells_het = sum(S.count_het);

S.fraction = S.count / S.N_cells;
S.fraction_homo = S.count_homo / S.N_cells_homo;
S.fraction_het = S.count_het / S.N_cells_homo;

[count_sorted, ind] = sort(S.count,'descend');

S.count_sorted = count_sorted;
S.count_het_sorted = S.count_het(ind);
S.count_homo_sorted = S.count_homo(ind);
S.cell_types_sorted = S.cell_types(ind);
