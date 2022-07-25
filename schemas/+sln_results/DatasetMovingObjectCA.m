%{
# DatasetMovingObjectCA
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
direction_by_condition : longblob # direction for each condition
directions : longblob # set of directions (degrees)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
n_epochs_per_condition : longblob # number of epochs in each condition
peak_firing_rate : longblob # peak firing rate (Hz)
peak_firing_time : longblob # peak_firing_time from start of epoch (ms)
peak_firing_time_from_center : longblob # peak firing time relative to time object is in screen center (ms)
psth_x_by_condition : longblob # struct of psth time axis for each condition
psth_x_from_center_by_condition : longblob # psth time axis recentered on the time the objet is in screen center
psth_y_by_condition : longblob # struct of psth firing rate axis for each condition
speed_by_condition : longblob # speed for each condition
speeds : longblob # set of speeds (microns / sec)
%}
classdef DatasetMovingObjectCA < dj.Manual
end
