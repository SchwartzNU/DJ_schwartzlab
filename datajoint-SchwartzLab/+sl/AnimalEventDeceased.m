%{
# mouse has left the house

event_id : int unsigned auto_increment
---
-> sl.Animal
(sacrificed_by) -> sl.User(name)
date : date
time = NULL : time
cause = NULL : enum('sacrificed not needed','sacrificed for experiment','other','unknown') #cause of death
notes = NULL : varchar(256)                                 # notes about the event
unique index (animal_id)
%}

classdef AnimalEventDeceased < sl.AnimalEvent & dj.Manual
end

