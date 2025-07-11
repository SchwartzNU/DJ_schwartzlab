%{
# DatasetUncaging
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
drug_condition : varchar(128) # drugs in the bath (free text)
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
group_names : varchar(128) # free text used to associate ROI files with this epoch
integrated_resp=NULL : longblob # sum response (mV*s) within time period (a parameter which defaults to 50 ms) using mean trace
laser_power=NULL : float # laser power (percent)
laser_wavelength=NULL : float # laser wavelength
n_epochs : int unsigned # number of epochs
number_of_sequences : int unsigned # number of repeats
number_of_stim_groups : int unsigned # number of different uncaging locations
peak_resp=NULL : longblob # peak of mean response across trials
resting_potential_mean=NULL : float # mean resting potential across all spot sizes (mV)
shutter_open : varchar(128) # T or F for shutter open
time_axis=NULL : longblob # time axis for each trace
traces_all=NULL : longblob # every trace aligned to each uncaging item
traces_mean=NULL : longblob # mean trace aligned to each uncaging item
traces_sem=NULL : longblob # sem of trace aligned to each uncaging item
trial_integrated_resp_mean=NULL : longblob # sum response (mV*s) within time period (a parameter which defaults to 50 ms), mean across trials
trial_integrated_resp_sem=NULL : longblob # sum response (mV*s) within time period (a parameter which defaults to 50 ms), sem across trials
trial_peak_resp_mean=NULL : longblob # mean of peak resp (mV) for each trial at each location
trial_peak_resp_sem=NULL : longblob # sem of peak resp (mV) for each trial at each location
%}
classdef DatasetUncaging < dj.Manual
end
