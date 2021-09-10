%{
# A symphony epoch
epoch_uuid: uuid
---
-> sln_symphony.SymphonyEpochBlock
start_time: int unsigned #number of milliseconds since midnight on the day the session started
duration: int unsigned #duration of the epoch in milliseconds

%}
classdef SymphonyEpoch < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end

%epoch parameters tie in here, depend on the protocol of the block...