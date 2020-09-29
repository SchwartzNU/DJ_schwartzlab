%{
# Eye
-> sl.Animal
side: enum('L', 'R', 'Unknown1', 'Unknown2')   # left, right, or unknown (could have 2 unknown eyes)
---
tags : longblob                 # struct with tags

%}

classdef Eye < dj.Manual 
end