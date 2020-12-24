%{
# Cell type
name_full : varchar(64)                  # full cell type name
cell_class : enum('RGC','bipolar','amacrine','horizontal','photoreceptor','other neuron','glia','pericyte','RPE cell','unknown','other')
---
name_short : varchar(32)                 # short name
name_for_var : varchar(32)               # name in form suitable for variables: no spaces or periods
notes = NULL: varchar(128)              # notes about this cell type
%}
classdef CellType < dj.Lookup
    
end