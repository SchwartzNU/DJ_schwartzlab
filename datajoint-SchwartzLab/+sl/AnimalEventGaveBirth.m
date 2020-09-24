%{
# babies!
event_id : int unsigned auto_increment
---
-> sl.Animal
number_of_pups : tinyint unsigned                    # how many babies
date : date
notes: varchar(128)                                  # anything
%}

classdef AnimalEventGaveBirth < sl.AnimalEvent & dj.Manual   

end

