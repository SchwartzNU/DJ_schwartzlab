%{
# Eye
-> sl.Animal
eye_id : tinyint unsigned
---
side: enum('Left', 'Right', 'Unknown')                 # left, right, or unknown
%}

classdef Eye < dj.Manual
    
end
