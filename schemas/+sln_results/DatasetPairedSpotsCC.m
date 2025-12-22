%{
# DatasetPairedSpotsCC
file_name : varchar(128) # file name from symphony
dataset_name : varchar(128) # dataset name
source_id : int unsigned # source id used to identify the cell to which the dataset belongs
---
-> sln_lab.User # user who entered this result
contrasts=NULL : longblob # array of Weber contrast values that specify the order of the data sets
entry_time = CURRENT_TIMESTAMP : timestamp # time the result was entered
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
n_epochs : int unsigned # number of epochs
paired_spot_data=NULL : longblob # cell array of dictionaries (by contrast) storing spike counts, center point, and distance between spots for each spot pair position
rstar_mean=NULL : float # intensity of background
sample_rate : int unsigned # sample rate (Hz)
single_spot_data=NULL : longblob # cell array of dictionaries (by contrast) storing spike counts for each spot position
spot_pre_frames : int unsigned # frames (at 60 Hz) of pre time for each spot
spot_size=NULL : float # size of spot (microns)
spot_stim_frames : int unsigned # frames (at 60 Hz) of stim time for each spot
spot_tail_frames : int unsigned # frames (at 60 Hz) of tail time for each spot
%}
classdef DatasetPairedSpotsCC < dj.Manual
end
