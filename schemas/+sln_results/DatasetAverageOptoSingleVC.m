%{
# DatasetAverageOptoSingleVC
file_name : varchar(128) # file name of the ephys file
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
average_trace=NULL : longblob # the average trace of the dataset
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
epoch_total : int unsigned # the total number of the epochs
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
pre_time_ms : int unsigned # time before stimulus onset (ms)
sample_rate : int unsigned # sampling rate of the recording
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetAverageOptoSingleVC < dj.Manual
end
