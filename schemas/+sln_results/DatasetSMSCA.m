%{
# DatasetSMSCA
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
---
baseline_rate_hz : float # baseline firing rate (in pre time) averaged across spot sizes (Hz)
n_epochs_per_size : longblob # vector with how many trials for each spot size
pre_time_ms : int unsigned # time before stimulus onset (ms)
spikes_pre_mean : longblob # spike count in pre time, mean
spikes_stim_mean : longblob # spike count in stim time, mean
spikes_stim_sem : longblob # spike count in stim time, standard error of the mean
spikes_tail_mean : longblob # spike count in tail time, mean
spikes_tail_sem : longblob # spike count in tail time, standard error of the mean
spot_sizes : longblob # set of spot sizes (microns)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetSMSCA < dj.Manual
end
