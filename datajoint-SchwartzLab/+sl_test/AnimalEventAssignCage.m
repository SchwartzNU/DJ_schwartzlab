%{
# animal has switched houses

event_id : int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

cause = NULL : enum('assigned at database insert','weaning','set as breeder','experiment','crowding','other','unknown') #assignment type/cause
notes = NULL : varchar(256)                                 # notes about the event

cage_number: int unsigned       # cage number mouse was moved to
%}


classdef AnimalEventAssignCage < sl_test.AnimalEvent & dj.Manual
    methods(Static)
        function cage = current()
            cage = sl_test.AnimalEventAssignCage() & 'LIMIT 1 PER animal_id DESC';
        end

        function cage = initial()
            cage = sl_test.AnimalEventAssignCage() & 'LIMIT 1 PER animal_id ASC';
        end
    end
    
end
% move_from_cage_number: int unsigned          # from cage number
% move_to_