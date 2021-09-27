%{
# A group of epochs in a symphony file
-> sln_symphony.SymphonySource
epoch_group_id: tinyint unsigned
---
epoch_group_start_time: datetime
epoch_group_end_time: datetime
epoch_group_label : varchar(32) #e.g., control, drug...
%}
classdef SymphonyEpochGroup < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end