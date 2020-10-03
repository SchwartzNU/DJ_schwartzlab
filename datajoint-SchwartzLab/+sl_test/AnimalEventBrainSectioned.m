%{
# brain sl_testicing

event_id:int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User # who did the sectioning
-> sl_test.Plane # how was the sectioning performed?
date:date
time:time
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

thickness:smallint unsigned #thickness of the sl_testice in microns

notes = NULL:varchar(256) # surgery notes (can include people who assisted)

%}
classdef AnimalEventBrainSectioned < sl_test.AnimalEvent & dj.Manual

    properties
        printStr = '%s: Animal %d brain sectioned in %s plane with thickness %d microns by %s.  (%s)\n';
        printFields = {'date', 'animal_id', 'orientation', 'thickness', 'user_name', 'notes'};
    end

end