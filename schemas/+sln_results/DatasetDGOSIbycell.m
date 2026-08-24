%{
#DatasetDGOSIbycell
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP  : timestamp # when it was computed
git_tag : varchar(128) # code version used
speed_used=NULL  :  longblob # filtered speed for computation
halfwidths=NULL : longblob  # set of cyclej (bar) halfwidths (microns)
contrasts=NULL   : longblob  # set of contrasts
halfwidth_by_condition=NULL  : longblob # halfwidth for each condition
contrast_by_condition=NULL  : longblob # contrast for each condition
preferred_angle_by_condition=NULL : longblob # preferred angle for each condition
preferred_orientation_by_condition=NULL : longblob # preferred orientation for each condition (folded 0-180)
dsi_by_condition=NULL : longblob # direction selectivity index for each condition
osi_by_condition=NULL : longblob # orientation selectivity index for each condition
%}
classdef DatasetDGOSIbycell < dj.Manual
end