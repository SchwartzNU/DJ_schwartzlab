%{
# change breeder status

event_id:int unsigned auto_increment
---
-> sl.Animal
-> sl.User
date:date
time = NULL:time
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

unique index (animal_id)
notes = NULL:varchar(256) # anything
%}

classdef AnimalEventRetireAsBreeder < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animal %d retired as breeder. User: %s. (%s)\n';
        printFields = {'date', 'animal_id', 'user_name' ,'notes'};
    end
    
end