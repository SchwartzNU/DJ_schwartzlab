%{
# DatasetLSflashesCA
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
baseline_rate_hz=NULL : float # baseline firing rate (in pre time (Hz)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
n_epochs : int unsigned # how many trials
pre_time_ms : int unsigned # time before stimulus onset (ms)
psth_x=NULL : longblob # x (time) values for psth (seconds)
psth_y=NULL : longblob # psth with 10 ms bins or other binning if specified in params
spikes_mean=NULL : float # spike count during and after flash, mean
spikes_sem=NULL : float # spike count during and after flash, standard error of the mean
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetLSflashesCA < dj.Manual
end
