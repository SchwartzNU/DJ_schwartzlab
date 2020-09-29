%{
# animal has switched houses

event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
<<<<<<< HEAD
cause = NULL : enum('assigned at database insert', 'weaning', 'set as breeder', 'experiment', 'crowding', 'other', 'unknown') #assignment type/cause
notes = NULL : varchar(256)                                 # notes about the event
cage_number: int unsigned       # cage number was assigned to
=======

cause = NULL : enum('assigned at database insert','weaning','set as breeder','experiment','crowding','other','unknown') #reason for move
notes = NULL : varchar(256)                                 # notes about the event

cage_number: int unsigned       # cage number mouse was moved to
>>>>>>> b5b06100d6d37fa75342a06db06f4c00b394179b
%}


classdef AnimalEventAssignCage < sl.AnimalEvent & dj.Manual
    methods(Static)
        function cage = current()
            cage = sl.AnimalEventAssignCage() & 'LIMIT 1 PER animal_id DESC';
        end

        function cage = initial()
            cage = sl.AnimalEventAssignCage() & 'LIMIT 1 PER animal_id ASC';
        end
    end
<<<<<<< HEAD
end
=======
    
end
% move_from_cage_number: int unsigned          # from cage number
% move_to_
>>>>>>> b5b06100d6d37fa75342a06db06f4c00b394179b
