%{
# babies!
event_id : int unsigned auto_increment
---
-> sl.Animal
number_of_pups : tinyint unsigned                    # how many babies
date : date
time = NULL : time    #unlikely to be recorded, but all events should have a time field

entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
notes: varchar(128)                                  # anything
%}

classdef AnimalEventGaveBirth < sl.AnimalEvent & dj.Manual
end

