%{
#Source notes
-> sln_symphony.ExperimentRetina
entry_time: datetime
---
text : blob@raw
%}
classdef ExperimentSourceNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Experiment;
end
end
