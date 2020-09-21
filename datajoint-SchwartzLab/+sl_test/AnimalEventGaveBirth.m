%{
# babies!
-> sl_test.AnimalEvent(labor_day='date')             # date of labor
---
number_of_pups : tinyint unsigned                    # how many babies
notes: varchar(128)                                  # anything
%}

classdef AnimalEventGaveBirth < dj.Part
     properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end

