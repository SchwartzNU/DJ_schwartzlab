%{
# EpochPostsynapticCurrent
file_name : varchar(128) # file name of the ephys file
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
epoch_id : int unsigned # epoch id of this recording
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
psc_amplitude=NULL : longblob # the vector denoting the peak amplitude of PSC
psc_decay_ms=NULL : longblob # decay time of the PSC in miliseconds
psc_risetime_ms=NULL : longblob # rise time of the PSC in miliseconds
psc_start_ms=NULL : longblob # the vector denoting the starting time of PSC in miliseconds
psc_total : int unsigned # total number of the detected PSC
sample_rate : int unsigned # sampling rate of this recording
%}
classdef EpochPostsynapticCurrent < dj.Manual
end
