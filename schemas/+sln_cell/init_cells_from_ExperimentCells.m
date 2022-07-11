exp_cells = sln_symphony.ExperimentCell * proj(sln_symphony.ExperimentRetina,'*','source_id->retina_source_id') * proj(sln_animal.Animal,'*','source_id->animal_source_id');
exp_cells_struct = rmfield(fetch(exp_cells),'retina_source_id');
insert(sln_cell.Cell,exp_cells_struct);

