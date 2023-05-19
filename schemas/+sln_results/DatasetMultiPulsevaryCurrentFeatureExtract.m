%{
# DatasetMultiPulsevaryCurrentFeatureExtract
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
Nspike_max_vs_last_epoch_ratio=NULL : longblob # Ratio of max number of spike over spikes from max depol epoch
V_threshold=NULL : longblob # AP threshold voltage (20% of max dV/dt) - from each trial (mV)
capacitance=NULL : longblob # membrane capacitance (pF) - from each trial
current_max_number_of_spike=NULL : longblob # Depolarization current at which max number of spikes is achieved
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
example_traces=NULL : longblob # waveforms of example traces (mV)
first_AP_peak_amplitude=NULL : longblob # First AP peak amplitude(mV)
first_AP_peak_time=NULL : longblob # First AP peak location (ms)
first_AP_trough_amplitude=NULL : longblob # First AP trough amplitude(mV)
first_AP_trough_time=NULL : longblob # First AP trough location (ms)
first_current_level_to_block=NULL : longblob # First current (pA) to get depol block
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
half_max_spike_current=NULL : longblob # Current at which half max of spike number on f-I curve
half_max_spike_number=NULL : longblob # Half max of spike numbers (increasing side only on f-I curve)
half_width_time=NULL : longblob # Half width time of first AP (ms) - from each trial (mV)
inj_current=NULL : longblob # vector of current injection amplitudes (pA)
max_63_percent_decay_time=NULL : longblob # Max time during depol current inj that AP decay 1/e (ms)
max_AHP_after_depol_injection=NULL : longblob # Max AHP after depol (to a find windows of 10ms) (mV)
max_ISI_CV=NULL : longblob # Max ISI CV of depol epochs from each trial
max_adaptation_index=NULL : longblob # Max adaptation index through all depolarization epochs of eacg trial
max_latency_of_spike=NULL : longblob # Max latency to first spike (ms)
max_number_of_spike=NULL : longblob # Max number of spikes from any depolarization epochs
max_slope=NULL : longblob # Max AP slope of first AP (V/s)
mean_traces=NULL : longblob # waveforms of mean traces (mV)
min_63_percent_decay_time=NULL : longblob # Min time during depol current inj that AP decay 1/e (ms)
n_epochs_per_current=NULL : longblob # vector with how many trials for each injection size
pre_time_ms=NULL : float # pre time (ms)
resistance=NULL : longblob # membrane resistance (MOhm) - array from each trial
resistance_Rsquared=NULL : longblob # GOF adjusted R square of resistance calculation - from each trial
sag=NULL : longblob # coefficient of sag amplitude in hyperpolarizing epochs - from each trial
sample_rate=NULL : float # samples per second
spontaneous_firing_rate=NULL : longblob # spontaneous firing rate at rest (Hz) - from each trial
spontenous_spike_amplitude_cv=NULL : longblob # CV of all spontaneous spikes amplitude
stim_time_ms=NULL : float # stim time (ms)
tau=NULL : longblob # membrane time constant (ms) - from each trial
tmax=NULL : longblob # time of maximum positive deflection during current (ms)
tmax_rebound=NULL : longblob # time of maximum positive deflection after current (mV)
tmin=NULL : longblob # time of minimum negative deflection during current (mV)
tmin_rebound=NULL : longblob # time of minimum negative deflection after current (mV)
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
