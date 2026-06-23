%{
# DatasetSMSVCinhibition
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
charge_stim_mean=NULL : longblob # integrated charge in stim time, mean
charge_stim_sem=NULL : longblob # integrated charge in stim time, standard error of the mean
charge_tail_mean=NULL : longblob # integrated charge in tail time, mean
charge_tail_sem=NULL : longblob # integrated charge in tail time, standard error of the mean
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
holding_current_mean=NULL : float # mean holding currentl across all spot sizes (pA)
holding_voltage=NULL : float # holding voltage (mV)
mean_traces=NULL : longblob # mean trace for each spot size
mean_zeroed_traces=NULL : longblob # mean zeroed trace for each spot size
n_epochs_per_size=NULL : longblob # vector with how many trials for each spot size
peak_stim_mean=NULL : longblob # peak current in stim time, mean (pA)
peak_stim_sem=NULL : longblob # peak current in stim time, standard error of the mean (pA)
peak_tail_mean=NULL : longblob # peak current in tail time, mean (pA)
peak_tail_sem=NULL : longblob # peak current in tail time, standard error of the mean (pA)
pre_time_ms : int unsigned # time before stimulus onset (ms)
sample_rate : int unsigned # sample rate (Hz)
spot_sizes=NULL : longblob # set of spot sizes (microns)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetSMSVCinhibition < dj.Manual
end
