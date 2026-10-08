%{
#DatasetDGspeedtuningbycell
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP  : timestamp # when it was computed
git_tag : varchar(128) # code version used
speeds=NULL  :  longblob # set of speeds for computation
halfwidths=NULL : longblob  # set of cycle (bar) halfwidths (microns)
contrasts=NULL   : longblob  # set of contrasts
speed_by_condition=NULL :   longblob # speed for each condition
halfwidth_by_condition=NULL  : longblob # halfwidth for each condition
contrast_by_condition=NULL  : longblob # contrast for each condition
preferred_angle_by_condition=NULL : longblob # preferred angle for each condition
preferred_orientation_by_condition=NULL : longblob # preferred orientation for each condition (folded 0-180)
dsi_by_condition=NULL : longblob # direction selectivity index for each condition
osi_by_condition=NULL : longblob # orientation selectivity index for each condition
peak_pref_angle_magnitude_by_condition=NULL :   longblob # magnitude at most responsive angle for each condition
peak_avg_magnitude_by_condition=NULL    :   longblob # magnitude averaged across all directions
%}

classdef DatasetDGspeedtuningbycell < dj.Manual
end