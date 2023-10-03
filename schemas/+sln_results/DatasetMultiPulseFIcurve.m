%{
# DatasetMultiPulseFIcurve
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
fr_per_current_mean=NULL : longblob # mean firing rate (Hz) for each current injection
fr_per_current_sem=NULL : longblob # sem of firing rate (Hz) for each current injection
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
inj_current=NULL : longblob # vector of current injection amplitudes (pA)
n_epochs_per_current=NULL : longblob # vector with how many trials for each injection size
stim_time_s=NULL : float # stimulus time (s)
%}
classdef DatasetMultiPulseFIcurve < dj.Manual
end
