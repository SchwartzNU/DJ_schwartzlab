%{
# DatasetSMSCC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
baseline_rate_hz=NULL : float # baseline spike rate in pre time (Hz)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_traces=NULL : longblob # example trace for each spot size
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
mean_traces=NULL : longblob # mean trace for each spot size
n_epochs_per_size=NULL : longblob # vector with how many trials for each spot size
peak_stim_mean=NULL : longblob # peak voltage in stim time, mean (mV)
peak_stim_sem=NULL : longblob # peak voltage in stim time, standard error of the mean (mV)
peak_tail_mean=NULL : longblob # peak voltage in tail time, mean (mV)
peak_tail_sem=NULL : longblob # peak voltage in tail time, standard error of the mean (mV)
pre_time_ms : int unsigned # time before stimulus onset (ms)
response_duration_stim=NULL : longblob # duration that response stays above 50 percent of its maximum during stim time (s)
response_duration_tail=NULL : longblob # duration that response stays above 50 percent of its maximum during tail time (s)
response_peak_time_stim=NULL : longblob # time of peak response during stim (s)
response_peak_time_tail=NULL : longblob # time of peak response during tail (s)
resting_potential_mean=NULL : float # mean resting potential across all spot sizes (mV)
sample_rate : int unsigned # sample rate (Hz)
spikes_stim_mean=NULL : longblob # spikes during stimulus time (note that automatic spike counting can add a few spikes when there are none)
spikes_stim_sem=NULL : longblob # sem of spike counts during stim
spikes_tail_mean=NULL : longblob # spikes during tail time (note that automatic spike counting can add a few spikes when there are none)
spikes_tail_sem=NULL : longblob # sem of spike counts during tail
spot_sizes=NULL : longblob # set of spot sizes (microns)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetSMSCC < dj.Manual
end
