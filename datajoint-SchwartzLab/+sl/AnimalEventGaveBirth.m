%{
# babies!
event_id:int unsigned auto_increment
---
-> sl.User
-> sl.Animal
-> sl.BreedingCage
number_of_pups:tinyint unsigned # how many babies
date:date
time = NULL:time #unlikely to be recorded, but all events should have a time field

entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

notes:varchar(128) # anything
%}

classdef AnimalEventGaveBirth < sl.AnimalEvent & dj.Manual

    properties
        printStr = '%s: Animal %d gave birth to %d pups in cage %s. User %s.(%s)\n';
        printFields = {'date', 'animal_id', 'number_of_pups', 'cage_number', 'user_name', 'notes'};
    end


end
