%{
#Experiment notes
-> sln_symphony.Symphony
note_index : tinyint unsigned
---
entry_time: datetime
text : blob@raw
%}
classdef SymphonyNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Symphony;
end
end
