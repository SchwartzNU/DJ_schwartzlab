%{
# 
-> sln_animal.AnimalEvent
---
-> sln_animal.GenotypeSource
%}
classdef GenotypeResult < dj.Manual
    properties
        printStr = '%s %s: Animal %d: Genotype result (%s) entered. User: %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'source_name', 'user_name' ,'notes'};
    end

end