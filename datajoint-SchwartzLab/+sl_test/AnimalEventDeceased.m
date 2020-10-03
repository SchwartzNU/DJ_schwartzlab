%{
# mouse has left the house

event_id:int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User
date:date
time = NULL:time
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

cause = NULL:enum('sacrificed not needed', 'sacrificed for experiment', 'other', 'unknown') #cause of death

unique index (animal_id)
notes:varchar(256) # anything
%}

classdef AnimalEventDeceased < sl_test.AnimalEvent & dj.Manual

    properties
        printStr = '%s %s: Animal %d deceased. Cause: %s. User: %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'cause', 'user_name' ,'notes'};
    end

    methods (Static)

        function animals = living()
            animals = sl_test.Animal() - sl_test.AnimalEventDeceased();
        end
    end

end
