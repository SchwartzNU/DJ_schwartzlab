%{
# DatasetPscOptoStats
file_name : varchar(128) # file name of the ephys file
dataset_name : varchar(128) # the name of the dataset
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
if_multi_pulse : int unsigned # 1 if train, 0 if not
latency_opto_ms=NULL : longblob # the timing diff between psc and previous opto stim onset. If psc occurs before any opto onset, it will be negative
opto_duration_ms : int unsigned # the duration of the said opt
pcs_frequency=NULL : float # number of psc/total time elapsed
psc_amp_mean=NULL : float # the average peak value of psc
psc_risetime_mean_s=NULL : float # average rise time
psc_total_dataset : int unsigned # total number of detected psc
%}
classdef DatasetPscOptoStats < dj.Manual
end
