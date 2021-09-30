%{
# A group of epochs in a symphony file
-> sln_symphony.ExperimentSource
epoch_group_id: tinyint unsigned
---
epoch_group_start_time: datetime
epoch_group_end_time: datetime
epoch_group_label : varchar(32) #e.g., control, drug...
%}
classdef ExperimentEpochGroup < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Experiment;
    end
end