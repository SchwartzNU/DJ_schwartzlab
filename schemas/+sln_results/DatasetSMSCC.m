%{
# DatasetSMSCC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
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
resting_potential_mean=NULL : float # mean resting potential across all spot sizes (mV)
sample_rate : int unsigned # sample rate (Hz)
spot_sizes=NULL : longblob # set of spot sizes (microns)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetSMSCC < dj.Manual
end
