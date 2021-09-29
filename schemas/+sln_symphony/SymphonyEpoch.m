%{
# A symphony epoch
-> sln_symphony.SymphonyEpochBlock
epoch_id : smallint unsigned
---
epoch_start_time: int unsigned #number of milliseconds since the session started
epoch_duration: int unsigned #duration of the epoch in milliseconds

%}
classdef SymphonyEpoch < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end

%epoch parameters tie in here, depend on the protocol of the block...