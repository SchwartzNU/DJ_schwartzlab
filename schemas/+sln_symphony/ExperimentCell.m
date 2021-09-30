%{
# A cell object in a symphony hdf5 file
-> sln_symphony.ExperimentSource
---
(retina_id) -> sln_symphony.ExperimentRetina(source_id)
cell_number = NULL : tinyint unsigned #sometimes different from source label
online_type = NULL: varchar(32)
x = NULL: smallint #microns from optic nerve, x direction
y = NULL: smallint

%}
classdef ExperimentCell < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end