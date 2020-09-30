%{
# for associating an animal with a project, used to prevent conflicting reservations

event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.Project
-> sl.User           #who made the reservation
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

notes = NULL : varchar(256)                                 # notes about the event

%}


classdef AnimalEventReservedForProject < sl.AnimalEvent & dj.Manual
    
end