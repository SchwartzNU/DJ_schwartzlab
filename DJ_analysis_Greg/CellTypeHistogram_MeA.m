function S = CellTypeHistogram_MeA(data_group)
inj_side = table;
inj_side.animal_id = [201, 425, 702, 780, 783, 1973]';
inj_side.side =      {'R', 'R', 'R', 'L', 'L', 'R'}';

L = height(inj_side);
sex_vec = cell(L,1);
for i=1:L
    sex_vec{i} = fetch1(sln_animal.Animal & sprintf('animal_id=%d',inj_side.animal_id(i)), 'sex');    
end

inj_side.sex = sex_vec;

cell_types = fetchn(sln_cell.Cell * sln_cell.AssignType.current & proj(data_group), 'cell_type');
animal_ids = fetchn(sln_cell.Cell * sln_cell.AssignType.current & proj(data_group), 'animal_id');

N = length(animal_ids);
M_R = false(N,1);
M_L = false(N,1);
F_R = false(N,1);
F_L = false(N,1);

for i=1:N
    ind = find(inj_side.animal_id == animal_ids(i));
    if strcmp(inj_side.sex(ind), 'Male')
        if strcmp(inj_side.side(ind), 'R')
            M_R(i) = true;
        else
            M_L(i) = true;
        end
    else
        if strcmp(inj_side.side(ind), 'R')
            F_R(i) = true;
        else
            F_L(i) = true;
        end
    end

end

unique_types = unique(cell_types);
N = length(unique_types);

S.cell_types = cell(N,1);
S.count = zeros(N,1);
S.fraction = cell(N,1);

S.count_MR = zeros(N,1);
S.fraction_MR = cell(N,1);
S.count_ML = zeros(N,1);
S.fraction_ML = cell(N,1);
S.count_FR = zeros(N,1);
S.fraction_FR = cell(N,1);
S.count_FL = zeros(N,1);
S.fraction_FL = cell(N,1);

for i=1:N
    S.cell_types{i} = unique_types{i};
    S.count(i) = sum(strcmp(cell_types,unique_types{i}));    
    S.count_MR(i) = sum(strcmp(cell_types(M_R),unique_types{i}));    
    S.count_ML(i) = sum(strcmp(cell_types(M_L),unique_types{i})); 
    S.count_FR(i) = sum(strcmp(cell_types(F_R),unique_types{i})); 
    S.count_FL(i) = sum(strcmp(cell_types(F_L),unique_types{i})); 
end

S.N_cells = sum(S.count);
S.N_cells_MR = sum(S.count_MR);
S.N_cells_ML = sum(S.count_ML);
S.N_cells_FR = sum(S.count_FR);
S.N_cells_FL = sum(S.count_FL);

S.fraction = S.count / S.N_cells;
S.fraction_MR = S.count_MR / S.N_cells_MR;
S.fraction_ML = S.count_ML / S.N_cells_ML;
S.fraction_FR = S.count_FR / S.N_cells_FR;
S.fraction_FL = S.count_FL / S.N_cells_FL;

[count_sorted, ind] = sort(S.count,'descend');

S.count_sorted = count_sorted;
S.count_MR_sorted = S.count_MR(ind);
S.count_ML_sorted = S.count_ML(ind);
S.count_FR_sorted = S.count_FR(ind);
S.count_FL_sorted = S.count_FL(ind);

S.cell_types_sorted = S.cell_types(ind);
