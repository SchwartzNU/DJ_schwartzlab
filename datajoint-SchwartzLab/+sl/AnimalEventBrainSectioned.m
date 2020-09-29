%{
# brain slicing

event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.User               # who did the sectioning
-> sl.Plane              # how was the sectioning performed?
date: date
time: time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

thickness: smallint unsigned    #thickness of the slice in microns

notes = NULL: varchar(256)           # surgery notes (can include people who assisted)

%}
classdef AnimalEventBrainSectioned < sl.AnimalEvent & dj.Manual
end
