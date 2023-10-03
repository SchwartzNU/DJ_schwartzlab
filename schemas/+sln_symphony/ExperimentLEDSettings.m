%{
# A group of settings for Stage protocols
-> sln_symphony.ExperimentEpochBlock
-> sln_symphony.LED
---
value : tinyint unsigned
%}
classdef ExperimentLEDSettings < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end