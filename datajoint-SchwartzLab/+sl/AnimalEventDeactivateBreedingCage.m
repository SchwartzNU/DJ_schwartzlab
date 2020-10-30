%{
# breeding cage inctive

event_id : int unsigned auto_increment
---
-> sl.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
notes = NULL : varchar(256)    # notes about the event
-> sl.BreedingCage             # cage_number to create as breeding cage
%}


classdef AnimalEventDeactivateBreedingCage < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animal cage %s activated. User: %s. (%s)\n';
        printFields = {'date','cage_number','user_name','notes'};
    end
    
end
