%{
#Run image analysis on tissue
-> sln_tissue.Task
---
outputs : blob # cell array listing the set of outputs
%}

classdef Analyze < dj.Manual
end