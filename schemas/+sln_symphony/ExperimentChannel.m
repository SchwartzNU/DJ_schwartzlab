%{
# A symphony recording channel
-> sln_symphony.ExperimentEpochBlock
-> sln_symphony.Channel
---
sample_rate : float # the sample rate for this channel in Hz
%}
classdef ExperimentChannel < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Experiment;
    end
end

%cells should associate here?