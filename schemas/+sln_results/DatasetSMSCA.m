%{
# DatasetSMSCA
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
baseline_rate_hz=NULL : float # baseline firing rate (in pre time) averaged across spot sizes (Hz)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
n_epochs_per_size=NULL : longblob # vector with how many trials for each spot size
pre_time_ms : int unsigned # time before stimulus onset (ms)
psth_x=NULL : longblob # x (time) values for psth (seconds)
sms_psth=NULL : longblob # full SMS psth image with 10 ms bins or other binning if specified in params
spikes_pre_mean=NULL : longblob # spike count in pre time, mean
spikes_stim_mean=NULL : longblob # spike count in stim time, mean
spikes_stim_sem=NULL : longblob # spike count in stim time, standard error of the mean
spikes_tail_mean=NULL : longblob # spike count in tail time, mean
spikes_tail_sem=NULL : longblob # spike count in tail time, standard error of the mean
spot_sizes=NULL : longblob # set of spot sizes (microns)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetSMSCA < dj.Manual
end
