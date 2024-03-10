%{
# EpochMovie
-> sln_funcimage.Alignment
-> sln_symphony.ExperimentEpoch
---
raw_movie : blob@raw #the actual raw movie data for this epoch
offset_ms : int # the number of ms this movie needs to be shifted to line up with the epoch 
%}
classdef EpochMovie < dj.Manual
end
