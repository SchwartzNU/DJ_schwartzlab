%{
# DatasetRampanalysis
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
ahp_max_mean=NULL : float # peak AHP - mean (mV)
ahp_max_std=NULL : float # peak AHP - standard deviation (mV)
block_current=NULL : float # current at which cell stops spiking (Hz)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
max_spike_frequency_mean=NULL : float # max instantaneous spike rate during stim (Hz)
mean_trace=NULL : longblob # mean trace (mV)
n_trial : int unsigned # number of trials
resting_vm=NULL : float # resting membrane potential (mV)
rheobase=NULL : longblob # lowest current to invoke a spike (pA)
rheobase_mean=NULL : float # pA
rheobase_std=NULL : float # pA
stimulus=NULL : longblob # generated injected current stimulus (pA)
tau_1_mean=NULL : float # fast tau of tail response - mean (s)
tau_1_sd=NULL : float # fast tau of tail response - standard deviation (s)
tau_2_mean=NULL : float # slow tau of tail response - mean (s)
tau_2_sd=NULL : float # slow tau of tail response - standard deviation (s)
%}
classdef DatasetRampanalysis < dj.Manual
end
