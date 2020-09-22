%{
# Any animal event
-> sl_test.Animal
datetime: datetime          #time of this event

%}

classdef AnimalEvent < dj.Manual
    
end

%event_id : smallint unsigned auto_increment               #unique event ID
