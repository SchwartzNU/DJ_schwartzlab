%{
# change breeder status
event_id                    : int unsigned AUTO_INCREMENT   # 
---
-> sl.Animal
-> sl.User
date                        : date                          # 
time=null                   : time                          # 
entry_time=CURRENT_TIMESTAMP: timestamp                     # when this was entered into db
notes                       : varchar(256)                  # anything
%}

classdef AnimalEventSetAsBreeder < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animal %d set as breeder. User: %s. (%s)\n';
        printFields = {'date', 'animal_id', 'user_name' ,'notes'};
    end
    
end
