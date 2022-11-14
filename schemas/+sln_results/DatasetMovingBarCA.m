%{
# DatasetMovingBarCA
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
bar_angles : longblob # set of bar angles (degrees)
bar_distance : int unsigned # travel distance (microns)
bar_length : int unsigned # bar length (microns)
bar_speed : int unsigned # bar speed (microns per second)
bar_width : int unsigned # bar width (microns
baseline_rate_hz : float # baseline spike rate in pre time (Hz)
ds_ang : float # ds angle for the full movement period (degrees)
ds_ang_leading : float # ds angle for the leading period (degrees)
ds_ang_trailing : float # ds angle for the leading trailing (degrees)
dsi : float # vector sum dsi for the full movement period
dsi_leading : float # vector sum dsi for the leading period
dsi_trailing : float # vector sum dsi for the trailing period
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
leading_trailing_index : longblob # spike count index defined as (leading - trailing) / (leading + trailing)
n_epochs_per_angle : longblob # vector with how many trials for each angle
peak_rate_leading : longblob # peak firing rate during the first half of the movement (Hz)
peak_rate_trailing : longblob # peak firing rate during the second half of the movement (Hz)
pre_time_ms : int unsigned # time before stimulus onset (ms)
psth_by_angle : longblob # psth image by bar angle with 10 ms bins or other binning if specified in params
psth_x : longblob # x (time) values for psth (seconds)
spikes_full_mean : longblob # spike count during bar movement mean
spikes_full_sem : longblob # spike count during bar movement sem
spikes_leading_mean : longblob # spike count during first half of bar movement (leading edge), mean
spikes_leading_sem : longblob # spike count during first half of bar movement (leading edge), sem
spikes_trailing_mean : longblob # spike count during second half of bar movement (trailing edge), mean
spikes_trailing_sem : longblob # spike count during second half of bar movement (trailing edge), sem
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetMovingBarCA < dj.Manual
end
