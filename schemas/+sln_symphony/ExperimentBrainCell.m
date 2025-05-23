%{
# A cell object in a symphony hdf5 file
-> sln_symphony.ExperimentSource
---
(brain_slice_id) -> [nullable] sln_symphony.ExperimentBrainSlice(source_id)
cell_number=null            : tinyint unsigned              # sometimes different from source label
(brain_region) ->sln_animal.BrainRegion
note = null:varchar(50)
%}
classdef ExperimentBrainCell < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end