%{
#
-> sln_animal.AnimalEvent
---
-> sln_animal.Cage
cause = "unknown" : enum('assigned at database insert','weaning','set as breeder','separated breeder','experiment','crowding','cage moved rooms','other','unknown') #assignment type/cause
%}

classdef AssignCage < dj.Manual
    properties
        printStr = '%s: Animal %d moved to cage %d in room %s. Cause: %s. User: %s. (%s)\n';
        printFields = {'date','animal_id','cage_number','room_number','cause','user_name','notes'};
    end

    methods(Static)
        function cage = current()
            %cage = sln_animal.AssignCage * sln_animal.AnimalEvent & 'LIMIT 1 PER animal_id ORDER BY date DESC, entry_time DESC';
            % slightly faster version: 
            cage = aggr(sln_animal.Animal, sln_animal.AssignCage * sln_animal.AnimalEvent,'convert(substring(max(concat(date,entry_time,cage_number)), 30),unsigned)->cage_number');
        end

        function cage = initial()
            cage = sln_animal.AssignCage * sln_animal.AnimalEvent & 'LIMIT 1 PER animal_id ORDER BY date ASC, entry_time ASC';
        end
    end
end