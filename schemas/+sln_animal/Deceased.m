%{
#
-> sln_animal.AnimalEvent
---
cause = NULL:enum('sacrificed not needed', 'sacrificed for experiment', 'other', 'unknown') #cause of death
%}
classdef Deceased < dj.Manual
    properties
        printStr = '%s %s: Animal %d deceased. Cause: %s. User: %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'cause', 'user_name' ,'notes'};
    end

    methods (Static)

        function animals = living()
            animals = sln_animal.Animal() - (sln_animal.AnimalEvent() * sln_animal.Deceased());
        end

    end

end