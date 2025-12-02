%{
# DatasetSpikeBrainCC
file_name : varchar(128) # file name of the ephys file
dataset_name : varchar(128) # the name of the dataset
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
baseline_mp_nostim=NULL : longblob # membrane potential of each epoch outside of stim period
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
mean_baseline_mp_nostim=NULL : float # the membrane potential outside of the stimulation period
mean_spike_count_in_stim : int unsigned # count of average spike inside the stim period
sample_rate : int unsigned # sample rate of thie epoch block
spike_count_out_stim : int unsigned # count of spike outside of stim
spike_count_within_stim : int unsigned # number of CC spikes inside the stimulation period
spike_frequency_all=NULL : float # frequency of spikes in and out of stim period
stim_duration_ms : int unsigned # duration of a stimulation period of one epoch
stim_protocol_name : varchar(128) # should be enum but that doesn't work for result table making functions.
stim_value=NULL : float # voltage or opto pulse frequency or single opto pulse duration
total_elapsed_time_s=NULL : float # total time duration of this epoch block
total_spike_count : int unsigned # number of CC spikes in this dataset
%}
classdef DatasetSpikeBrainCC < dj.Manual
end
