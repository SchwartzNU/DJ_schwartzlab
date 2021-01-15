%{
#pups weaned
event_id:int unsigned auto_increment
---
-> sl.User
-> sl.BreedingCage
number_of_pups:tinyint unsigned # how many weaned
date:date
time = NULL:time #unlikely to be recorded, but all events should have a time field

entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

notes:varchar(128) # anything
%}

classdef AnimalEventWeaned < sl.AnimalEvent & dj.Manual

    properties
        printStr = '%s: Weaned to %d pups from breeding cage %s. User %s.(%s)\n';
        printFields = {'date', 'number_of_pups', 'cage_number', 'user_name', 'notes'};
    end


end
