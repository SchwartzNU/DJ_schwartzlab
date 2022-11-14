%{
# DatasetSMSVC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
charge_stim_mean=NULL : longblob # charge duriung stim time, mean
charge_stim_sem=NULL : longblob # charge duriung stim time, standard error of the mean
charge_tail_mean=NULL : longblob # charge duriung tail time, mean
charge_tail_sem=NULL : longblob # charge duriung tail time, standard error of the mean
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
holding_current_mean=NULL : float # mean holding current across all spot sizes
mean_traces=NULL : longblob # mean trace for each spot size
n_epochs_per_size=NULL : longblob # vector with how many trials for each spot size
peak_stim_mean=NULL : longblob # peak current in stim time, mean
peak_stim_sem=NULL : longblob # peak current in stim time, standard error of the mean
peak_tail_mean=NULL : longblob # peak current in tail time, mean
peak_tail_sem=NULL : longblob # peak current in tail time, standard error of the mean
pre_time_ms : int unsigned # time before stimulus onset (ms)
sample_rate : int unsigned # sample rate (Hz)
spot_sizes=NULL : longblob # set of spot sizes (microns)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetSMSVC < dj.Manual
end
