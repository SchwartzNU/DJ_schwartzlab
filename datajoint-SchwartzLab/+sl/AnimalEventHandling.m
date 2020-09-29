%{
# just handling mice to get them used to humans
event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.User                   # handler
date: date
time: time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
duration : int unsigned                  # approximate duration (minutes)

notes = NULL : varchar(256)                                  # notes about the animal's state and comfort level
%}

classdef AnimalEventHandling < sl.AnimalEvent & dj.Manual
end

