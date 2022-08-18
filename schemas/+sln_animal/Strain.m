%{ 
# The name of a strain of animals, used to reflect intended genotype

strain_name                 : varchar(64) 
->sln_animal.Background
---
-> sln_animal.Species

%}
classdef Strain < dj.Manual
end