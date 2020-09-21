%{
# just handling mice to get them used to humans
-> sl.AnimalEvent                               # includes date
---
duration_mins : smallint unsigned                    # approximate duration (minutes)
notes: varchar(256)                                  # notes about the animal's state and comfort level
-> sl.User(handled_by='name')                   # who did it
%}

classdef AnimalEventHandling < dj.Part
     properties(SetAccess=protected)
        master = sl.AnimalEvent
    end
end

