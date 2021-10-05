%{
# A block of recording epochs in a symphony file
-> sln_symphony.ExperimentEpochGroup
epoch_block_id: tinyint unsigned
---
-> sln_symphony.Protocol
epoch_block_start_time: datetime
epoch_block_end_time: datetime

%}
classdef ExperimentEpochBlock < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Experiment;
    end
end

%epoch block parameters tie in here, depend on the protocol...