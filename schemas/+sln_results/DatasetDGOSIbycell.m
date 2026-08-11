%{
#DatasetDGOSIbycell
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
contrasts=NULL   : longblob  # set of contrasts
contrast_by_condition=NULL  : longblob # contrast for each condition
DSI_by_condition=NULL : longblob # direction selectivity index for each condition
entry_time - CURRENT_TIMESTAMP  : timestamp # when it was computed
git_tag : varchar(128) # code version used
halfwidths=NULL : longblob  # set of cyclej (bar) halfwidths (microns)
halfwidth_by_condition=NULL  : longblob # helfwidth for each condition
OSI_by_condition=NULL : longblob # orientation selectivity index for each condition
preferred_angle_by_condition=NULL : longblob # preferredn angle for each condition
speed_used=NULL  :  longblob # filtered speed for computation
%}
classdef DatasetDGOSIbycell < dj.Manual
end