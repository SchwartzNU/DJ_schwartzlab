%{
#Epoch notes
-> sln_symphony.SymphonyEpoch
entry_time: datetime
---
text : blob@raw
%}
classdef SymphonyEpochNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Symphony;
end
end
