%{
# DatasetDriftingGratingsCC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
contrast_by_condition=NULL : longblob # contrasts for each condition
contrasts=NULL : longblob # set of contrasts
cycle_avg_amplitude=NULL : longblob # peak to peak amplitude of cycle average trace (mV)
cycle_avg_peak_neg=NULL : longblob # negative peak of cycle average trace (mV)
cycle_avg_peak_pos=NULL : longblob # positive peak of cycle average trace (mV)
cycle_avg_trace_by_condition=NULL : longblob # cycle average trace for each condition (mV)
direction_by_condition=NULL : longblob # direction for each condition
directions=NULL : longblob # set of directions of movement (degrees)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_trace_by_condition=NULL : longblob # example trace for each condition (mV)
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
half_width_by_condition=NULL : longblob # half-width for each condition
half_widths=NULL : longblob # set of cycle (bar) half widths (microns)
mean_resting_potential=NULL : float # 
movement_delay_ms : int unsigned # delay after grating onset before it starts moving (ms)
n_epochs_per_condition=NULL : longblob # number of epochs in each condition
pre_time_ms : int unsigned # pre time (ms)
resting_potential_mean=NULL : float # mean resting potential across all conditions (mV)
sample_rate : int unsigned # sample rate (Hz)
speed_by_condition=NULL : longblob # speed for each condition
speeds=NULL : longblob # set of speeds (microns / sec)
%}
classdef DatasetDriftingGratingsCC < dj.Manual
end
