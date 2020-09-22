%{
# mouse has left the house
(animal_id, dod) -> sl_test.AnimalEvent(animal_id, datetime)
---
cause = NULL : enum('sacrificed not needed','sacrificed for experiment','other','unknown')  # cause of death
notes: varchar(128)                                  # anything
(sacrificed_by) -> sl_test.User(name)                # who did the deed (need to add empty user for this)
unique index (animal_id)
%}

classdef AnimalEventDeceased < dj.Part
     properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end

