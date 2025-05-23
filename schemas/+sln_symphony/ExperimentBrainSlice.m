%{
# A brain nslice object (primary 'source') in a symphony hdf5 file
-> sln_symphony.ExperimentSource
---
->sln_tissue.BrainSliceBatch
(experimenter) -> [nullable] sln_lab.User #redundant already in sln_tissue.BrainSliceBatch 
%}
classdef ExperimentBrainSlice < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end