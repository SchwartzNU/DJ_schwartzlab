%{
# A cell object in a symphony hdf5 file
-> sln_symphony.ExperimentSource
---
(retina_id) -> sln_symphony.ExperimentRetina(source_id)
cell_number=null            : tinyint unsigned              # sometimes different from source label
online_type=null            : varchar(64)                   # 
x=null                      : smallint                      # microns from optic nerve, x direction
y=null                      : smallint                      # 
%}
classdef ExperimentCell < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end