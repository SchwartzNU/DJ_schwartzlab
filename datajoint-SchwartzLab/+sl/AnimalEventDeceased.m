%{
# mouse has left the house
-> sl.AnimalEvent                    # includes date of death
---
cause = NULL : enum('sacrificed not needed','sacrificed for experiment','other','unknown')  # cause of death
notes: varchar(128)                             # anything
(sacrificed_by) -> sl.User(name)                # who did the deed (need to add empty user for this)

%}

classdef AnimalEventDeceased < dj.Part
     properties(SetAccess=protected)
        master = sl.AnimalEvent
    end
end
%need to make a method to remove the animal from the Live list
