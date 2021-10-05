%{
#An experiment note
-> sln_symphony.Experiment
entry_time: datetime
---
text : blob@raw
%}
classdef ExperimentNote < sln_symphony.ExperimentPart
properties(SetAccess=protected)
    master = sln_symphony.Experiment;
end
end
