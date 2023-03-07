%{
# DatasetDriftingGratingsCA
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : float # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
baseline_rate_hz=NULL : float # baseline firing rate (in pre time) averaged across conditions
contrast_by_condition=NULL : longblob # contrasts for each condition
contrasts=NULL : longblob # set of contrasts
cycle_avg_amplitude=NULL : longblob # peak to peak amplitude of PSTH (Hz)
cycle_avg_psth_by_condition=NULL : longblob # cycle average PSTH for each condition (Hz)
direction_by_condition=NULL : longblob # direction for each condition
directions=NULL : longblob # set of directions of movement (degrees)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
halfwidth_by_condition=NULL : longblob # half-width for each condition
halfwidths=NULL : longblob # set of cycle (bar) half widths (microns)
movement_delay_ms=NULL : float # delay after grating onset before it starts moving (ms)
n_epochs_per_condition=NULL : longblob # number of epochs in each condition
pre_time_ms=NULL : float # pre time (ms)
psth_by_condition_x=NULL : longblob # full PSTH for each condition x values  (s)
psth_by_condition_y=NULL : longblob # full PSTH for each condition (Hz)
speed_by_condition=NULL : longblob # speed for each condition
speeds=NULL : longblob # set of speeds (microns / sec)
stim_condition_list=NULL : longblob # list of stimulus condtions that can vary - for plotter menus
%}
classdef DatasetDriftingGratingsCA < dj.Manual
end
