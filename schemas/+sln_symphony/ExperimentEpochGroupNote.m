%{
#Epoch Group notes
-> sln_symphony.ExperimentEpochGroup
entry_time: datetime
---
text : blob@raw
%}
classdef ExperimentEpochGroupNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Experiment;
end
end
