%{
# DatasetMovingBarCC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
bar_angles=NULL : longblob # set of bar angles (degrees)
bar_distance : int unsigned # travel distance (microns)
bar_length : int unsigned # bar length (microns)
bar_speed : int unsigned # bar speed (microns per second)
bar_width : int unsigned # bar width (microns
ds_ang_leading_peak=NULL : float # peak-based ds angle for the leading period (degrees)
ds_ang_peak=NULL : float # peak-based ds angle for the full movement period (degrees)
ds_ang_trailing_peak=NULL : float # peak-based ds angle for the trailing period (degrees)
dsi_leading_peak=NULL : float # peak-based vector sum dsi for the leading period
dsi_peak=NULL : float # peak-based vector sum dsi for the full movement period
dsi_trailing_peak=NULL : float # peak-based vector sum dsi for the trailing period
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_traces_by_angle=NULL : longblob # example trace for each bar angle
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
leading_trailing_index_peak=NULL : longblob # peak-based index defined as (leading - trailing) / (leading + trailing)
mean_traces_by_angle=NULL : longblob # mean trace for each bar angle
n_epochs_per_angle=NULL : longblob # vector with how many trials for each angle
peak_full_mean=NULL : longblob # peak voltage during bar movement mean (pA)
peak_full_sem=NULL : longblob # peak voltage during bar movement sem (mV)
peak_leading_mean=NULL : longblob # peak voltage during first half of bar movement (leading edge), mean (mV)
peak_leading_sem=NULL : longblob # peak voltage during first half of bar movement (leading edge), sem (mV)
peak_trailing_mean=NULL : longblob # peak voltage during second half of bar movement (trailing edge), mean (mV)
peak_trailing_sem=NULL : longblob # peak voltage during second half of bar movement (trailing edge), sem (mV)
pre_time_ms : int unsigned # time before stimulus onset (ms)
resting_potential_mean=NULL : float # mean resting potential (mV)
sample_rate : int unsigned # sample_rate (Hz)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after stimulus offset (ms)
%}
classdef DatasetMovingBarCC < dj.Manual
end
