%{
# DatasetMultiPulsespikewaveform
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
average_spike=NULL : longblob # averaged spike (mV)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
rheobase_mean=NULL : float # mean smallest recorded current to evoke spikes (pA)
spike_diff=NULL : longblob # diff of AP (mV/ms)
time_vector=NULL : longblob # time vector of aligned spike (ms)
%}
classdef DatasetMultiPulsespikewaveform < dj.Manual
end
