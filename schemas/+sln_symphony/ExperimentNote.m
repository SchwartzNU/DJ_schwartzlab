%{
#An experiment note
-> sln_symphony.Experiment
entry_time: datetime
---
text : blob@raw
%}
classdef ExperimentNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Experiment;
end
end
