%{
#Flattened cell trace and morphological parameters
->sln_cell.RetinalCell
---
nodes_flattened : longblob
edges_flattened : longblob
radii_flattened : longblob
branch_lengths : longblob
branch_angles : longblob
branch_z_range : longblob
branch_tortuosity : longblob
strat_x : longblob
strat_density : longblob
strat_y_norm : longblob
n_branches : smallint unsigned
arbor_length : float
arbor_complexity : float
arbor_density : float
bistratified : tinyint unsigned
polygon_area = null : float
convexity_index = null : float
polygon_area_lower = null : float
convexity_index_lower = null : float
polygon_area_upper = null : float
convexity_index_upper = null : float
%}
classdef RetinalCellMorphology < dj.Manual

end
