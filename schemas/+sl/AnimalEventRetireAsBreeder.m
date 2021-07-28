%{
# change breeder status
event_id                    : int unsigned AUTO_INCREMENT   # 
---
-> sl.Animal
-> sl.User
date                        : date                          # 
time=null                   : time                          # 
entry_time=CURRENT_TIMESTAMP: timestamp                     # when this was entered into db
notes=null                  : varchar(256)                  # anything
%}

classdef AnimalEventRetireAsBreeder < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animal %d retired as breeder. User: %s. (%s)\n';
        printFields = {'date', 'animal_id', 'user_name' ,'notes'};
    end
    
end
