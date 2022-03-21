%{
# 
-> sln_animal.Genotype
---
-> sln_animal.AnimalEvent
-> sln_animal.GenotypeSource
%}
classdef GenotypeResult < dj.Part
    properties
        master = sln_animal.Genotype;
    end
end