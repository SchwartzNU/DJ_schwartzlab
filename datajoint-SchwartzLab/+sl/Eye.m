%{
# Eye
-> sl.Animal
eye_id : tinyint unsigned
---
side: enum('L', 'R', 'Unknown')                 # left, right, or unknown
%}

classdef Eye < dj.Manual
    
end
