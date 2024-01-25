%{
# DatasetRadialSpotsCA
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
n_epochs : int unsigned # number of epochs
pre_time_ms : int unsigned # baseline before each spot presentation (ms)
rstar_intensity_spot=NULL : float # intensity of spot
sample_rate : int unsigned # sample rate (Hz)
spike_count_matrix_mean=NULL : longblob # spike count for matrix in the same format as trace_matrix_mean
spike_count_matrix_sem=NULL : longblob # sem of spike_count_matrix_mean
spot_ang=NULL : longblob # array of spot angles (radians)
spot_dist=NULL : longblob # array of spot distances (microns)
spot_size=NULL : float # size of spot (microns)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after each spot presentation (ms)
%}
classdef DatasetRadialSpotsCA < dj.Manual
end
