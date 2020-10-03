%{
# IP injection of tamoxifen or some other substance
event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.InjectionSubstance
-> sl.User                          # who did the injection
date : date
time: time                    # time of day
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

concentration: float                 # mg per Kg body weight
notes = NULL : varchar(256)          # notes about the event
%}


classdef AnimalEventIPinjection < sl.AnimalEvent & dj.Manual
    
    methods(Access=public)
        function s = printEvent(self)
            eventStruct = fetch(self,'*');
            if isempty(eventStruct.notes)
                notes = '';
            else
                notes = sprintf('(%s)',eventStruct.notes);
            end
            s = sprintf('%s: %s: Animal %d had an IP injection of %s, %d mg/kg performed by %s. %s', ...
                eventStruct.date,...
                eventStruct.time,...
                eventStruct.animal_id,...
                eventStruct.substance_name,...
                eventStruct.concentration,...
                eventStruct.user_name,...
                notes);
        end        
    end
    
end
