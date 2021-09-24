%{
#Epoch Group notes
-> sln_symphony.SymphonyEpochGroup
note_index : tinyint unsigned
---
entry_time: datetime
text : blob@raw
%}
classdef SymphonyEpochGroupNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Symphony;
end
end
