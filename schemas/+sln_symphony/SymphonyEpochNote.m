%{
#Epoch notes
-> sln_symphony.SymphonyEpoch
note_index : tinyint unsigned
---
entry_time: datetime
text : blob@raw
%}
classdef SymphonyEpochNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Symphony;
end
end