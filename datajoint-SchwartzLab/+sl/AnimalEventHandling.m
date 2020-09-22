%{
# just handling mice to get them used to humans
-> sl.AnimalEvent                               # includes date
---
duration_mins : smallint unsigned                    # approximate duration (minutes)
notes: varchar(256)                                  # notes about the animal's state and comfort level
(handled_by) -> sl.User(name)                   # who did it
handle_time: time                    # time of day
%}

classdef AnimalEventHandling < dj.Part
     properties(SetAccess=protected)
        master = sl.AnimalEvent
    end
end

