%{
# Tag the animal
event_id:int unsigned auto_increment
---
-> sl.Animal
tag_id = NULL : int unsigned    # tag number
tag_ear = 'Unknown' : enum('None', 'L', 'R', 'Unknown')   # which ear has the tag
punch = 'None' : enum('L','R','Both','None')      # earpunch
-> sl.User # who did the tag
date = NULL:date
time = NULL:time
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db
notes = NULL:varchar(256) # notes about the event
%}

classdef AnimalEventTag < sl.AnimalEvent & dj.Manual

    properties
        printStr = '%s: Animal %d given tag id: %d, ear punch: %s, performed by %s. (%s)\n';
        printFields = {'date', 'animal_id', 'tag_id', 'punch', 'user_name', 'notes'};
    end
    
     methods(Static)
        function tag = current()
            tag = sl.AnimalEventTag & 'LIMIT 1 PER animal_id DESC';
        end

        function tag = initial()
            tag = sl.AnimalEventTag() & 'LIMIT 1 PER animal_id ASC';
        end
    end

end
