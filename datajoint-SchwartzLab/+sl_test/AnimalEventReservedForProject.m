%{
# for associating an animal with a project, used to prevent conflicting reservations

event_id:int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.Project
-> sl_test.User #who made the reservation
date:date
time = NULL:time
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

notes = NULL:varchar(256) # notes about the event

%}

classdef AnimalEventReservedForProject < sl_test.AnimalEvent & dj.Manual

    properties
        printStr = '%s: Animal %d reserved for project "%s" by %s. (%s)\n';
        printFields = {'date', 'animal_id', 'project_name', 'user_name', 'notes'};
    end

end
