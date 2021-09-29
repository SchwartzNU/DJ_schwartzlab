%{
# A symphony recording channel for a single epoch
-> sln_symphony.ExperimentEpoch
-> sln_symphony.ExperimentChannel
---
raw_data : blob@raw #the actual raw data for this epoch

%}
classdef ExperimentEpochChannel < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Experiment;
    end
end
