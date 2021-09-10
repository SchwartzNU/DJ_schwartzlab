%{
# A block of epochs in a symphony file
epoch_block_uuid: uuid
---
-> sln_symphony.Protocol
-> sln_symphony.SymphonyEpochGroup
start_time: datetime
end_time: datetime

%}
classdef SymphonyEpochBlock < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end

%epoch block parameters tie in here, depend on the protocol...