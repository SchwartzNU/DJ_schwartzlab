%{
# DatasetIVLightStep
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
hold_voltages=NULL : longblob # set of hold voltages (mV)
holding_current=NULL : longblob # mean holding current for each holding voltage
mean_current_by_timeslice_mean=NULL : longblob # mean current across holding voltage for each timeslice (pA), mean across trials
mean_current_by_timeslice_sem=NULL : longblob # mean current across holding voltage for each timeslice (pA), sem across trials
mean_traces=NULL : longblob # mean trace for each holding voltage
n_epochs_per_hold=NULL : longblob # vector with how many trials for each holding voltage
peak_current_by_timeslice_mean=NULL : longblob # peak current across holding voltage for each timeslice (pA), mean across trials
peak_current_by_timeslice_sem=NULL : longblob # peak current across holding voltage for each timeslice (pA), sem across trials
pre_time_ms : int unsigned # time before stimulus onset (ms)
sample_rate : int unsigned # sample rate (Hz)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
timeslices=NULL : longblob # start and end of each time slice for measuring current (ms) column 1 is starttime, column 2 is endtime, 0 is stim_start
%}
classdef DatasetIVLightStep < dj.Manual
end
