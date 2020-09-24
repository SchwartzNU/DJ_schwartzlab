%{
# just handling mice to get them used to humans
event_id : int unsigned auto_increment
---
-> sl.Animal
date: date
handle_time: time
duration_mins : smallint unsigned                    # approximate duration (minutes)
notes = NULL : varchar(256)                                  # notes about the animal's state and comfort level
(handled_by)-> sl.User(name)                   # who did it
%}

classdef AnimalEventHandling < sl.AnimalEvent & dj.Manual   

end

