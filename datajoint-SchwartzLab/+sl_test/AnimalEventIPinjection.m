%{
# IP injection of tamoxifen or some other substance
event_id:int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.InjectionSubstance
-> sl_test.User # who did the injection
date:date
time:time # time of day
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

concentration:float # mg per Kg body weight
notes = NULL:varchar(256) # notes about the event
%}

classdef AnimalEventIPinjection < sl_test.AnimalEvent & dj.Manual

    properties
        printStr = '%s %s: Animal %d had an IP injection of %s, %d mg/kg performed by %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'substance_name', 'concentration', 'user_name', 'notes'};
    end

end
