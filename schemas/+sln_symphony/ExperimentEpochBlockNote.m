%{
#An epoch block note
-> sln_symphony.ExperimentEpochBlock
entry_time: datetime
---
text : blob@raw
%}
classdef ExperimentEpochBlockNote < sln_symphony.ExperimentPart
properties(SetAccess=protected)
    master = sln_symphony.Experiment;
end
end
