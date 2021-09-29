%{
# A pair of cells in a symphony hdf5 file, for a paired recording
-> sln_symphony.ExperimentSource
---
(cell_1_id) -> sln_symphony.ExperimentCell(source_id) #cell in amp channel 1
(cell_2_id) -> sln_symphony.ExperimentCell(source_id) #cell in amp channel 2

%}
classdef ExperimentCellPair < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end