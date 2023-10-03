%{
# animals paired for breeding
event_id                    : int unsigned AUTO_INCREMENT   # 
---
 (male_id) -> sl.Animal
 (female_id) -> sl.Animal
-> sl.User
date                        : date                          # 
time=null                   : time                          # 
entry_time=CURRENT_TIMESTAMP: timestamp                     # when this was entered into db
notes=null                  : varchar(256)                  # notes about the event
-> sl.BreedingCage
-> sl.AnimalCageRoom
%}


classdef AnimalEventPairBreeders < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animals %d (male) and %d (female) moved to cage %s in room %s as breeding pair. User: %s. (%s)\n';
        printFields = {'date','male_id', 'female_id','cage_number','room_number','user_name','notes'};
    end
    
end
