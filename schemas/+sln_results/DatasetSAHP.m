%{
# DatasetSAHP
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : float # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
ahp_amplitude=NULL : longblob # amplitude of after-hyperpolarization
ahp_areas=NULL : longblob # vector with AHP areas for each epoch.
auc_sp_ratios=NULL : longblob # vector with ahp_area over spike_count for each epoch
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_ahp=NULL : longblob # ahp area for the example traces
example_diff=NULL : longblob # Vector with differences of AHP voltage and vrest.
example_segment=NULL : float # Vector with the voltage of the post stimulation segment
example_sp=NULL : longblob # Idk. Was drunk when I coded this
example_spike_count=NULL : float # Vector of spike counts for the example traces
example_traces=NULL : longblob # waveforms of example traces (mV). Usually the first epoch.
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
inj_current=NULL : longblob # vector of current injection amplitudes (pA)
n_epochs_per_current=NULL : longblob # vector with how many trials for each injection size
pre_time_ms=NULL : float # pre time (ms)
sample_rate=NULL : float # samples per second
spike_counts=NULL : longblob # vector with spike counts for each epoch
stim_end_idx=NULL : longblob # stimuli end index
stim_end_time=NULL : float # stim end time
stim_time_ms=NULL : float # stim time (ms)
vrest_example=NULL : float # vrest of the example trace
%}
classdef DatasetSAHP < dj.Manual
end
