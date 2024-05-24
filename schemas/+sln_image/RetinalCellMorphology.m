%{
# An image of a cell
->sln_animal.Eye
->sln_cell.Cell
->sln_cell.CellImage
---
x=null                      : smallint                      # microns from optic nerve, x direction
y=null                      : smallint                      # 
image_notes = NULL: varchar(128)    #notes about certainty of typology or anything else
nodes_flattened = longblog
edges_flattened = longblog
strat_x = longblog
strat_density = longblog
strat_y_norm = longblog
arbor data stuff
%}
classdef RetinalCellMorphology < dj.Manual


end