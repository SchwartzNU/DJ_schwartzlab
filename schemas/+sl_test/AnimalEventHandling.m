%{
# just handling mice to get them used to humans
event_id:int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User # handler
date:date
time:time
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db
duration:time # approximate duration

notes = NULL:varchar(256) # notes about the animal's state and comfort level
%}

classdef AnimalEventHandling < sl_test.AnimalEvent & dj.Manual

    properties
        printStr = '%s %s: Animal %d handled by %s for %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'user_name', 'duration', 'notes'};
    end

end
