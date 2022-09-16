%{ 
# Optional additional info about an animal available at insertion, such
# as an ID number from another lab
-> sln_animal.Animal
---
external_info: varchar(512) #stores some text

%}

classdef AnimalExternal < dj.Part
    properties (SetAccess = protected)
        master = sln_animal.Animal
    end
end