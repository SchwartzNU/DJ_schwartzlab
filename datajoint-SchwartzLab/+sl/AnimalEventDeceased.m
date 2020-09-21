%{
# mouse has left the house
-> sl.AnimalEvent(dod='date')                   # date of death
---
cause = NULL : enum('sacrificed not needed','sacrificed for experiment','other','unknown')  # cause of death
notes: varchar(128)                                  # anything
-> sl.User(sacrificed_by='name')                # who did the deed (need to add empty user for this)

%}

classdef AnimalEventDeceased < dj.Part
     properties(SetAccess=protected)
        master = sl.AnimalEvent
    end
end

