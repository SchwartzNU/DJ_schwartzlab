%{
#A recording epoch note
-> sln_symphony.ExperimentEpoch
entry_time: datetime
---
text : blob@raw
%}
classdef ExperimentEpochNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Experiment;
end
end
