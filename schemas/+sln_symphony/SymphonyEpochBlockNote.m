%{
#Epoch block
-> sln_symphony.SymphonyEpochBlock
note_index : tinyint unsigned
---
entry_time: datetime
text : blob@raw
%}
classdef SymphonyEpochBlockNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Symphony;
end
end
