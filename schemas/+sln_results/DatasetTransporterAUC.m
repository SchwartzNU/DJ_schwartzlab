%{
# DatasetTransporterAUC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : float # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
ahp_amplitude=NULL : longblob # amplitude of after-hyperpolarization
ahp_decay_tau1=NULL : longblob # fast time constant of expotential decay back to baseline (s)
ahp_decay_tau2=NULL : longblob # slow time constant of expotential decay back to baseline (s)
ahp_tau1_coeff=NULL : longblob # weight of the fast exponent (remainder is the slow one)
ahp_time=NULL : longblob # time of after-hyperpolarization (s)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_traces=NULL : longblob # waveforms of example traces (mV)
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
inj_current=NULL : longblob # vector of current injection amplitudes (pA)
mean_traces=NULL : longblob # waveforms of mean traces (mV)
n_epochs_per_current=NULL : longblob # vector with how many trials for each injection size
pre_time_ms=NULL : float # pre time (ms)
sample_rate=NULL : float # samples per second
spike_count_all=NULL : longblob # spike count for each epoch at each current value
spike_count_mean=NULL : longblob # mean spike count during step for each current injection value
spike_count_sem=NULL : longblob # stanrdard error of spike count during step for each current injection value
stim_time_ms=NULL : float # stim time (ms)
vrest=NULL : float # mean resting potential (mV) overall
vrest_by_epoch=NULL : longblob # resting potential (mV) for each epoch at each current value
vrest_mean=NULL : longblob # mean resting potential (mV) for each current injection value
%}
classdef DatasetTransporterAUC < dj.Manual
end
