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
        % printStr = '%s %s: Animal %d had a brain injection of %s dilluted 1:%d targeting the %s %s. Coordinates (AP,ML,DV,angle): [%0.2f, %0.2f, %0.2f]. Performed by %s. (%s)\n';
        % printFields = {'date', 'time', 'animal_id', 'substance_name', 'dilution', 'hemisphere', 'target', 'coords', 'user_name', 'notes'};
    end

end
