%{
# DatasetMultiPulsevaryCurrentFeatureExtracttest
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
capacitance=NULL : longblob # membrane capacitance (pf)  from each trial
current_max_number_of_spike=NULL : longblob # 
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_traces=NULL : longblob # waveforms of example traces (mV)
first_ap_peak_amplitude=NULL : longblob # 
first_ap_peak_time=NULL : longblob # 
first_ap_trough_amplitude=NULL : longblob # 
first_ap_trough_time=NULL : longblob # 
first_current_level_to_block=NULL : longblob # 
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
half_max_spike_current=NULL : longblob # 
half_max_spike_number=NULL : longblob # 
half_width_time=NULL : longblob # 
inj_current=NULL : longblob # vector of current injection amplitudes (pA)
max_63_percent_decay_time=NULL : longblob # 
max_adaptation_index=NULL : longblob # 
max_ahp_after_depol_injection=NULL : longblob # 
max_isi_cv=NULL : longblob # 
max_latency_of_spike=NULL : longblob # 
max_number_of_spike=NULL : longblob # 
max_slope=NULL : longblob # 
mean_traces=NULL : longblob # waveforms of mean traces (mV)
min_63_percent_decay_time=NULL : longblob # 
n_epochs_per_current=NULL : longblob # vector with how many trials for each injection size
nspike_ratio=NULL : longblob # 
pre_time_ms=NULL : float # pre time (ms)
resistance=NULL : longblob # membrane resistance (mohm)  array from each trial
resistance_rsquared=NULL : longblob # gof adjusted r square of resistance calculation  from each trial
sag=NULL : longblob # coefficient of sag amplitude in hyperpolarizing eps  from each trial
sample_rate=NULL : float # samples per second
spontaneous_firing_rate=NULL : longblob # spontaneous firing rate at rest (hz)  from each trial
spontenous_spike_amplitude_cv=NULL : longblob # 
stim_time_ms=NULL : float # stim time (ms)
tau=NULL : longblob # membrane time constant (ms)  from each trial
tmax=NULL : longblob # time of maximum positive deflection during current (ms)
tmax_rebound=NULL : longblob # time of maximum positive deflection after current (mV)
tmin=NULL : longblob # time of minimum negative deflection during current (mV)
tmin_rebound=NULL : longblob # time of minimum negative deflection after current (mV)
v_threshold=NULL : longblob # ap threshold voltage (20 percent of max dvdt)  from each trial (mv)
vmax=NULL : longblob # maximum positive deflection above steady state during current (mV)
vmax_norm=NULL : longblob # maximum positive deflection above steady state during current (normalized to max)
vmax_rebound=NULL : longblob # maximum positive deflection after current (mV)
vmin=NULL : longblob # minimum negative deflection during current (mV)
vmin_rebound=NULL : longblob # minimum negative deflection after current (mV)
vrest=NULL : float # resting potential (mV)
vsteady=NULL : longblob # steady state deflection during last 50 ms of current (mV)
%}
classdef DatasetMultiPulsevaryCurrentFeatureExtracttest < dj.Manual
end
