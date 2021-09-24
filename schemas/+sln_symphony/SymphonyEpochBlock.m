%{
# A block of epochs in a symphony file
-> sln_symphony.SymphonyEpochGroup
epoch_block_id: tinyint unsigned
---
-> sln_symphony.Protocol
epoch_block_start_time: datetime
epoch_block_end_time: datetime

%}
classdef SymphonyEpochBlock < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end

%epoch block parameters tie in here, depend on the protocol...