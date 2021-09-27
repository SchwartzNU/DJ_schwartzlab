%{
#Cell notes
-> sln_symphony.SymphonyCell
note_index : tinyint unsigned
---
entry_time: datetime
text : blob@raw
%}
classdef SymphonyCellNote < dj.Part
properties(SetAccess=protected)
    master = sln_symphony.Symphony;
end
end
