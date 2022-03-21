%{
# For animals with a vendor as the source, identifies the associated line
-> sln_animal.Animal
-> sln_animal.Line
---
%}

classdef AnimalLine < dj.Manual
    properties
        master = sln_animal.Animal;
    end
end

