%{
# DatasetUncaging
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
n_epochs : int unsigned # number of epochs
resting_potential_mean=NULL : float # mean resting potential across all spot sizes (mV)
time_axis=NULL : longblob # time axis for each trace
traces_all=NULL : longblob # every trace aligned to each uncaging item
traces_mean=NULL : longblob # mean trace aligned to each uncaging item
%}
classdef DatasetUncaging < dj.Manual
end