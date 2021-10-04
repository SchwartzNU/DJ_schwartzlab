%{
#Epoch notes
-> sln_symphony.ExperimentEpoch
entry_time: datetime
---
text : blob@raw
%}
classdef ExperimentEpochNote < sln_symphony.ExperimentPart
properties(SetAccess=protected)
    master = sln_symphony.Experiment;
end
end
