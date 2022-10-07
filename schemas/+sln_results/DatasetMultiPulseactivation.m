%{
# DatasetMultiPulseactivation
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
stim1_time_ms : int unsigned # stim1 time (ms)
stim2_time_ms : int unsigned # stim2 time (ms)
tmax : longblob # time of vmax
tmin : longblob # time of vmin
vmax : longblob # maximum positive deflection above steady Vm during positive current (mV)
vmax_norm : longblob # Vmax normalized for activation curve
vmin : longblob # minimum negative deflection from steady Vm after positive deflection (mV)
vmin_norm : longblob # Vmin normalized for activation curve
vrest : float # resting potential (mV)
vsteady : longblob # steady state deflection during last 50 ms of current (mV)
%}
classdef DatasetMultiPulseactivation < dj.Manual
end
