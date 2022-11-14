%{
# DatasetMovingObjectCC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
direction_by_condition=NULL : longblob # direction for each condition
directions=NULL : longblob # set of directions (degrees)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
mean_resting_potential=NULL : float # 
mean_trace_by_condition=NULL : longblob # struct of time axis for each condition
n_epochs_per_condition=NULL : longblob # number of epochs in each condition
peak=NULL : longblob # peak current rate (pA)
peak_time=NULL : longblob # time of peak current from start of epoch (s)
peak_time_from_center=NULL : longblob # time of peak current relative to time object is in screen center (s)
resting_potential_mean=NULL : float # mean resting potential across all conditions (mV)
speed_by_condition=NULL : longblob # speed for each condition
speeds=NULL : longblob # set of speeds (microns / sec)
x_by_condition=NULL : longblob # struct of mean trace for each condition
x_from_center_by_condition=NULL : longblob # struct of time axis recentered on the time the objet is in screen center
%}
classdef DatasetMovingObjectCC < dj.Manual
end
