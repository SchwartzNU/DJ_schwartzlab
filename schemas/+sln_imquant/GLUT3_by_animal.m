function q = GLUT3_by_animal
q = aggr(sln_animal.Animal * sln_animal.GenotypeString & sln_imquant.GLUT3Stack,...
    proj(sln_imquant.GLUT3_by_stack,'age_at_exp','n_cells'),...
    'count(*)->n_stacks',...
    'max(age_at_exp)->age',...
    'sum(n_cells)->n_cells_total',...
    '*');
