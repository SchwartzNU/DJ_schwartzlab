%{
# session reservations for rig scheduling

event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.User           #who will be running the session
-> sl.Rig          #where will the session occur?

date : date           #date the session take place?
time : time           #time the session will start
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db


notes = NULL : varchar(256)                                 # notes about the event

%}


classdef AnimalEventReservedForProject < sl.AnimalEvent & dj.Manual
    
end