%{
# for associating an animal with a project, used to prevent conflicting reservations

-> sln_animal.AnimalEvent
---
-> sln_lab.Project

%}

classdef ReservedForProject < dj.Manual

    properties
        printStr = '%s: Animal %d reserved for project "%s" by %s. (%s)\n';
        printFields = {'date', 'animal_id', 'project_name', 'user_name', 'notes'};
    end

end
