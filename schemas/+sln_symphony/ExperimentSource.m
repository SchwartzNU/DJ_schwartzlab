%{
# A source object in a symphony hdf5 file
-> sln_symphony.Experiment
source_id : tinyint unsigned
---
source_label : varchar(32)
%}
classdef ExperimentSource < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end

% TODO: ought to be a shared table, whenever that is implemented