%{
# DatasetMultiPulsevaryCurrentFeatureExtract
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_traces=NULL : longblob # waveforms of example traces (mV)
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
inj_current=NULL : longblob # vector of current injection amplitudes (pA)
mean_traces=NULL : longblob # waveforms of mean traces (mV)
n_epochs_per_current=NULL : longblob # vector with how many trials for each injection size
pre_time_ms=NULL : float # pre time (ms)
sample_rate=NULL : float # samples per second
stim_time_ms=NULL : float # stim time (ms)
tmax=NULL : longblob # time of maximum positive deflection during current (ms)
tmax_rebound=NULL : longblob # time of maximum positive deflection after current (mV)
tmin=NULL : longblob # time of minimum negative deflection during current (mV)
tmin_rebound=NULL : longblob # time of minimum negative deflection after current (mV)
vmax=NULL : longblob # maximum positive deflection above steady state during current (mV)
vmax_norm=NULL : longblob # maximum positive deflection above steady state during current (normalized to max)
vmax_rebound=NULL : longblob # maximum positive deflection after current (mV)
vmin=NULL : longblob # minimum negative deflection during current (mV)
vmin_rebound=NULL : longblob # minimum negative deflection after current (mV)
vrest=NULL : float # resting potential (mV)
vsteady=NULL : longblob # steady state deflection during last 50 ms of current (mV)
%}
classdef DatasetMultiPulsevaryCurrentFeatureExtract < dj.Manual
end
