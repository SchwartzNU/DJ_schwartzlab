%{
# A retina object (primary 'source') in a symphony hdf5 file
-> sln_symphony.ExperimentSource
---
-> sln_animal.Eye
(experimenter) -> [nullable] sl.User
orientation: enum('ventral down', 'ventral up', 'unknown')
%}
classdef ExperimentRetina < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end

%this class is not particularly extensible... but works for now as a model of symphony files