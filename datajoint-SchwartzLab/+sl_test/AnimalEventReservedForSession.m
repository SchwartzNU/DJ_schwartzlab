%{
# session reservations for rig scheduling

event_id : int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User           #who will be running the session
-> sl_test.Rig            #where will the session occur?

date : date           #date the session take place?
time = NULL : time          
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db


notes = NULL : varchar(256)                                 # notes about the event

%}


classdef AnimalEventReservedForSession < sl_test.AnimalEvent & dj.Manual
    
    methods(Access=public)
        function s = printEvent(self)
            eventStruct = fetch(self,'*');
            if isempty(eventStruct.notes)
                notes = '';
            else
                notes = sprintf('(%s)',eventStruct.notes);
            end
            s = sprintf('%s: Animal %d reserved for experiment on %s, rig "%s" by %s. %s', ...
                eventStruct.entry_time,...
                eventStruct.animal_id,...
                eventStruct.date,...
                eventStruct.rig_name,...
                eventStruct.user_name,...                
                notes);
        end
    end
    
end