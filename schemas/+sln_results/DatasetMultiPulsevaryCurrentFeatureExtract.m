%{
# DatasetMultiPulsevaryCurrentFeatureExtract
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
capacitance=NULL : longblob # membrane capacitance (pf)  from each trial
current_max_number_of_spike=NULL : longblob # depolarization current at which max number of spikes is achieved
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_traces=NULL : longblob # waveforms of example traces (mV)
first_ap_peak_amplitude=NULL : longblob # first ap peak amplitude(mv)
first_ap_peak_time=NULL : longblob # first ap peak location (ms)
first_ap_trough_amplitude=NULL : longblob # first ap trough amplitude(mv)
first_ap_trough_time=NULL : longblob # first ap trough location (ms)
first_current_level_to_block=NULL : longblob # first current (pa) to get depol block
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
half_max_spike_current=NULL : longblob # current at which half max of spike number on fi curve
half_max_spike_number=NULL : longblob # half max of spike numbers (increasing side only on fi curve)
half_width_time=NULL : longblob # half width time of first ap (ms)  from each trial (mv)
inj_current=NULL : longblob # vector of current injection amplitudes (pA)
isi_cv_at_max_spikes=NULL : longblob # isi cv at current which gives max number of spikes
max_63_percent_decay_time=NULL : longblob # max time during depol current inj that ap decay 1e (ms)
max_adaptation_index=NULL : longblob # max adaptation index through all depolarization eps of eacg trial
max_ahp_after_depol_injection=NULL : longblob # max ahp after depol (to a find windows of 10ms) (mv)
max_isi_cv=NULL : longblob # max isi cv of depol eps from each trial
max_latency_of_spike=NULL : longblob # max latency to first spike (ms)
max_number_of_spike=NULL : longblob # max number of spikes from any depolarization eps
max_slope=NULL : longblob # max ap slope of first ap (vs)
mean_traces=NULL : longblob # waveforms of mean traces (mV)
min_63_percent_decay_time=NULL : longblob # min time during depol current inj that ap decay 1e (ms)
n_epochs_per_current=NULL : longblob # vector with how many trials for each injection size
nspike_ratio=NULL : longblob # max number of spike over last depolarizing epoch number of spikes
pre_time_ms=NULL : float # pre time (ms)
resistance=NULL : longblob # membrane resistance (mohm)  array from each trial
resistance_rsquared=NULL : longblob # gof adjusted r square of resistance calculation  from each trial
resting_vm=NULL : longblob # resting membrane potential calculated up to prestim by each trial
resting_vm_sd=NULL : longblob # resting vm sd upto prestim within each trial
sag=NULL : longblob # coefficient of sag amplitude in hyperpolarizing eps  from each trial
sample_rate=NULL : float # samples per second
spontaneous_firing_rate=NULL : longblob # spontaneous firing rate at rest (hz)  from each trial
spontenous_spike_amplitude_cv=NULL : longblob # cv of all spontaneous spikes amplitude
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
classdef DatasetMultiPulsevaryCurrentFeatureExtract < dj.Manual
end
