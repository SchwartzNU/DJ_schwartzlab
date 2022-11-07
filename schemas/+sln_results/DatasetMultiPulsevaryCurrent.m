%{
# DatasetMultiPulsevaryCurrent
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
inj_current : longblob # vector of current injection amplitudes (pA)
mean_traces : longblob # waveforms of mean traces (mV)
n_epochs_per_current : longblob # vector with how many trials for each injection size
pre_time_ms : int unsigned # pre time (ms)
sample_rate : float # samples per second
stim_time_ms : int unsigned # stim time (ms)
tmax : longblob # time of maximum positive deflection during current (ms)
tmax_rebound : longblob # time of maximum positive deflection after current (mV)
tmin : longblob # time of minimum negative deflection during current (mV)
tmin_rebound : longblob # time of minimum negative deflection after current (mV)
vmax : longblob # maximum positive deflection during current (mV)
vmax_rebound : longblob # maximum positive deflection after current (mV)
vmin : longblob # minimum negative deflection during current (mV)
vmin_rebound : longblob # minimum negative deflection after current (mV)
vrest : float # resting potential (mV)
vsteady : longblob # steady state deflection during last 50 ms of current (mV)
%}
classdef DatasetMultiPulsevaryCurrent < dj.Manual
end
