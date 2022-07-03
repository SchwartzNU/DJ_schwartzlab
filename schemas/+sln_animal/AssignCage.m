%{
#
-> sln_animal.AnimalEvent
---
-> sln_animal.Cage
cause = "unknown" : enum('assigned at database insert','weaning','set as breeder','separated breeder','experiment','crowding','cage moved rooms','other','unknown') #assignment type/cause

%}
classdef AssignCage < dj.Manual
    properties
        printStr = '%s: Animal %d moved to cage %s in room %s. Cause: %s. User: %s. (%s)\n';
        printFields = {'date','animal_id','cage_number','room_number','cause','user_name','notes'};
    end

    methods(Static)
        function cage = current()
            cage = sln_animal.AssignCage * sln_animal.Animal & 'LIMIT 1 PER animal_id DESC';
        end

        function cage = initial()
            cage = sln_animal.AssignCage() & 'LIMIT 1 PER animal_id ASC';
        end
    end
end