%{
# babies!
-> sl.AnimalEvent                                    # event
---
number_of_pups : tinyint unsigned                    # how many babies
notes: varchar(128)                                  # anything
%}

classdef AnimalEventGaveBirth < dj.Part
     properties(SetAccess=protected)
        master = sl.AnimalEvent
    end
end

