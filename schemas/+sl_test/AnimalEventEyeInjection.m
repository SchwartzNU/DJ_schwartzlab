%{
# eye injections
event_id : int unsigned auto_increment
---
-> sl_test.InjectionSubstance
-> sl_test.Eye
-> sl_test.User                      # who did the injection
time: time                    # time of day
date : date
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

dilution: float                      # dilution of substance
notes: varchar(256)                  # injection notes (can include people who assisted)
%}

classdef AnimalEventEyeInjection < sl_test.AnimalEvent & dj.Manual
        
    properties
        printStr = '%s %s: Animal %d had a %s eye injection of %s, dilluted 1:%d, performed by %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'side', 'substance_name', 'dilution', 'user_name', 'notes'};
    end
    
end
