%{
#An epoch group note
-> sln_symphony.ExperimentEpochGroup
entry_time: datetime
---
text : blob@raw
%}
classdef ExperimentEpochGroupNote < sln_symphony.ExperimentPart
properties(SetAccess=protected)
    master = sln_symphony.Experiment;
end
end
