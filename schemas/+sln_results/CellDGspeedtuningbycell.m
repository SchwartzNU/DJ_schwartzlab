%{
# CellDGspeedtuningbycell
cell_unid : int unsigned # cell_id_number
---
-> sln_lab.User # user who entered this result
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
max_cycle_avg_amplitude=NULL : longblob # maximum peak to peak amplitude of cycle average trace (mV)
max_cycle_avg_peak_pos=NULL : longblob # maximum positive peak of cycle average trace (mV)
mean_cycle_avg_amplitude=NULL : longblob # mean peak to peak amplitude of cycle average trace across directions (mV)
mean_cycle_avg_peak_neg=NULL : longblob # mean negative peak of cycle average trace (mV)
mean_cycle_avg_peak_pos=NULL : longblob # mean positive peak of cycle average trace (mV)
min_cycle_avg_peak_neg=NULL : longblob # minimum negative peak of cycle average trace (mV)
speeds=NULL : longblob # set of speeds (microns / sec)
%}
classdef CellDGspeedtuningbycell < dj.Manual
end
