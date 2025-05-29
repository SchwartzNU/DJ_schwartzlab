%{
# A brain object (primary 'source') in a symphony hdf5 file
-> sln_symphony.ExperimentSource
---
-> sln_animal.Animal
(experimenter) -> [nullable] sln_lab.User
thickness : smallint unsigned 
%}
classdef ExperimentBrain < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end
