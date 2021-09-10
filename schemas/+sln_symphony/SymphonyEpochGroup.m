%{
# A group of epochs in a symphony file
epoch_group_uuid: uuid
---
-> sln_symphony.SymphonySource
start_time: datetime
end_time: datetime
label : varchar(32) #e.g., control, drug...
%}
classdef SymphonyEpochGroup < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end