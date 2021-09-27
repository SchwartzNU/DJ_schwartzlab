%{
#Retina notes
-> sln_symphony.SymphonyRetina
note_index : tinyint unsigned
---
entry_time: datetime
text : blob@raw
%}
classdef SymphonyRetinaNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Symphony;
end
end
