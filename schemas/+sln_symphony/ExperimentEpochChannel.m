%{
# A symphony recording channel for a single epoch, and the attachment point for raw data
-> sln_symphony.ExperimentEpoch
-> sln_symphony.ExperimentChannel
---
raw_data : blob@raw #the actual raw data for this epoch
%}
classdef ExperimentEpochChannel < sln_symphony.ExperimentPart
    properties(SetAccess=protected)
        master = sln_symphony.Experiment;
    end
end
