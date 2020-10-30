%{
# animals paired for breeding

event_id : int unsigned auto_increment
---
(male_id) -> sl.Animal(animal_id)
(female_id) -> sl.Animal(animal_id)
-> sl.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

notes = NULL : varchar(256)    # notes about the event

-> sl.BreedingCage             # cage_number to create as breeding cage
-> sl.AnimalCageRoom           # room_number
%}


classdef AnimalEventPairBreeders < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animals %d (male) and %d (female) moved to cage %s in room %s as breeding pair. User: %s. (%s)\n';
        printFields = {'date','male_id', 'female_id','cage_number','room_number','user_name','notes'};
    end
    
end
