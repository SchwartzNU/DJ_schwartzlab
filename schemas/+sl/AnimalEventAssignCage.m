%{
# animal has switched houses

event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

cause = NULL : enum('assigned at database insert','weaning','set as breeder','separated breeder','experiment','crowding','cage moved rooms','other','unknown') #assignment type/cause
notes = NULL : varchar(256)                                 # notes about the event

cage_number: varchar(32)       # cage number mouse was moved to (alphanumeric)
-> sl.AnimalCageRoom
%}


classdef AnimalEventAssignCage < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animal %d moved to cage %s in room %s. Cause: %s. User: %s. (%s)\n';
        printFields = {'date','animal_id','cage_number','room_number','cause','user_name','notes'};
    end

    methods(Static)
        function cage = current()
            cage = sl.AnimalEventAssignCage() & 'LIMIT 1 PER animal_id DESC';
        end

        function cage = initial()
            cage = sl.AnimalEventAssignCage() & 'LIMIT 1 PER animal_id ASC';
        end
    end
    
end
