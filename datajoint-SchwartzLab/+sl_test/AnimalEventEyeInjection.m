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
    
    methods(Access=public)
        function s = printEvent(self)
            eventStruct = fetch(self,'*');
            if isempty(eventStruct.notes)
                notes = '';
            else
                notes = sprintf('(%s)',eventStruct.notes);
            end
            s = sprintf('%s %s: Animal %d had a %s eye injection of %s, dilluted 1:%d, performed by %s. %s', ...
                eventStruct.date,...
                eventStruct.time,...
                eventStruct.animal_id,...
                eventStruct.side,...
                eventStruct.substance_name,...
                eventStruct.dilution,...
                eventStruct.user_name,...
                notes);
        end        
    end
    
end
