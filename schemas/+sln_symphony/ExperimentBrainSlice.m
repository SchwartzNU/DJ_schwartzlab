%{
# A brain slice object in a symphony hdf5 file
-> sln_symphony.ExperimentSource
---
(brain_id) -> [nullable] sln_symphony.ExperimentBrain(source_id)
slice_notes : varchar(256)
%}
classdef ExperimentBrainSlice < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end