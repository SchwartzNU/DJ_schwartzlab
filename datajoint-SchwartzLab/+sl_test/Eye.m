%{
# Eye
-> sl_test.Animal
side: enum('Left', 'Right', 'Unknown1', 'Unknown2')   # left, right, or unknown (could have 2 unknown eyes)

%}

classdef Eye < dj.Manual 
end