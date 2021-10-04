%{
# A symphony epoch
-> sln_symphony.ExperimentEpochBlock
epoch_id : smallint unsigned
---
epoch_start_time: int unsigned #number of milliseconds since the session started
epoch_duration: int unsigned #duration of the epoch in milliseconds

%}
classdef ExperimentEpoch < sln_symphony.ExperimentPart
    properties(SetAccess=protected)
        master = sln_symphony.Experiment;
    end
end

%epoch parameters tie in here, depend on the protocol of the block...