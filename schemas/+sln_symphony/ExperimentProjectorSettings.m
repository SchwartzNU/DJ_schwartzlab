%{
# A group of settings for Stage protocols
-> sln_symphony.ExperimentEpochBlock
---
ndf : tinyint unsigned
bit_depth : tinyint unsigned
frame_rate : tinyint unsigned
offset_x : decimal(4,0)
offset_y : decimal(4,0)
%}
classdef ExperimentProjectorSettings < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end