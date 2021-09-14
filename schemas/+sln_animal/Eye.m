%{
# Eye
-> sln_animal.Animal
side: enum('Left', 'Right', 'UnknownA', 'UnknownB')   # left, right, or unknown (could have 2 unknown eyes)

%}

classdef Eye < dj.Manual 
end