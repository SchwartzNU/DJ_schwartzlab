%{
# Any animal event
-> sl_test.Animal
datetime: datetime          #time of this event
---
notes: varchar(128)                                  # anything

%}

classdef AnimalEvent < dj.Manual
    
end

%event_id : smallint unsigned auto_increment               #unique event ID
