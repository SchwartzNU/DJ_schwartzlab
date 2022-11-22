%{
# UserParamAnimalAnimalType
-> sln_animal.Animal
---
animal_type = NULL : varchar(64) # Like strain_name but more flexible to include whatever we want.
%}
classdef UserParamAnimalAnimalType < dj.Manual
end
