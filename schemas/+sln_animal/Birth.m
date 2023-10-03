%{
# Log the birth of a litter
-> sln_animal.AnimalEvent
%}

classdef Birth < dj.Manual
    properties
        printStr = '%s: Birth in for breeding pair %d in cage %d. User %s.(%s)\n';
        printFields = {'date', 'source_id', 'cage_number', 'user_name', 'notes'};
    end

end
