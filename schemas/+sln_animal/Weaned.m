%{
# Log the weaning of a litter
-> sln_animal.AnimalEvent
---
number_of_pups:tinyint unsigned # how many weaned
-> sln_animal.BreedingPair
-> sln_animal.Cage
%}

classdef Weaned < dj.Manual
    properties
        printStr = '%s: Weaned %d pups from breeding pair %d in cage %d. User %s.(%s)\n';
        printFields = {'date', 'number_of_pups', 'source_id', 'cage_number', 'user_name', 'notes'};
    end

end
