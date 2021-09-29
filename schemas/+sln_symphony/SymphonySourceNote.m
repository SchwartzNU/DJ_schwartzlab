%{
#Source notes
-> sln_symphony.SymphonyRetina
entry_time: datetime
---
text : blob@raw
%}
classdef SymphonySourceNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Symphony;
end
end
