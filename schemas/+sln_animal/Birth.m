%{
# Log the birth of a litter
-> sln_animal.AnimalEvent
%}

classdef Birth < dj.Manual
    properties
        printStr = '%s: Birth User %s.(%s)\n';
        printFields = {'date', 'user_name', 'notes'};
    end

end
