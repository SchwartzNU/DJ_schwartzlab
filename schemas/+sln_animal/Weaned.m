%{
# Log the weaning of a litter
-> sln_animal.AnimalEvent
---
number_of_pups              : tinyint unsigned              # how many weaned
%}

classdef Weaned < dj.Manual
    properties
        printStr = '%s: Weaned %d pups. User %s.(%s)\n';
        printFields = {'date', 'number_of_pups',  'user_name', 'notes'};
    end

end
