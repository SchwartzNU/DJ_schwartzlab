%{
# babies!
event_id:int unsigned auto_increment
---
-> sl_test.Animal
number_of_pups:tinyint unsigned # how many babies
date:date
time = NULL:time #unlikely to be recorded, but all events should have a time field

entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

notes:varchar(128) # anything
%}

classdef AnimalEventGaveBirth < sl_test.AnimalEvent & dj.Manual

    properties
        printStr = '%s: Animal %d gave birth to %d pups. (%s)\n';
        printFields = {'date', 'animal_id', 'number_of_pups', 'notes'};
    end


end
