%{
#Run image analysis on tissue
-> sln_tissue.Task
---
outputs : varchar(256) # string listing the set of outputs
%}

classdef Analyze < dj.Manual
end