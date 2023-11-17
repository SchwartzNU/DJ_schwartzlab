%{
# DatasetRadialSpotsVC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
charge_matrix=NULL : longblob # charge of each trace in trace_matrix_mean
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
n_epochs : int unsigned # number of epochs
peak_matrix_mean=NULL : longblob # peak inward current (pA) of traces in the same matrix format as trace_matrix_mean
peak_matrix_sem=NULL : longblob # sem of peak_matrix_mean
pre_time_ms : int unsigned # baseline before each spot presentation (ms)
rstar_intensity_spot=NULL : float # intensity of spot
sample_rate : int unsigned # sample rate (Hz)
spot_ang=NULL : longblob # array of spot angles (radians)
spot_dist=NULL : longblob # array of spot distances (microns)
spot_size=NULL : float # size of spot (microns)
stim_time_ms : int unsigned # stimulus presentation time (ms)
tail_time_ms : int unsigned # time after each spot presentation (ms)
trace_matrix_mean=NULL : longblob # mean trace aligned to each spot in a matrix where rows are angles and columns are distances
trace_matrix_sem=NULL : longblob # sem of trace_matrix
%}
classdef DatasetRadialSpotsVC < dj.Manual
end
