%{
# animals separated from breeding pair

event_id : int unsigned auto_increment
---
(male_id) -> sl.Animal(animal_id)
(female_id) -> sl.Animal(animal_id)
-> sl.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

notes = NULL : varchar(256)    # notes about the event

-> sl.BreedingCage             # cage_number to deactivate
new_cage_male : varchar(32)
new_cage_female : varchar(32)
(new_room_male) -> sl.AnimalCageRoom           # room_number
(new_room_female) -> sl.AnimalCageRoom           # room_number
%}


classdef AnimalEventSeparateBreeders < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animals %d (male) and %d (female) from cage %s in room %s separated as breeding pair. User: %s. (%s)\n';
        printFields = {'date','male_id', 'female_id','cage_number','room_number','user_name','notes'};
    end
    
end
