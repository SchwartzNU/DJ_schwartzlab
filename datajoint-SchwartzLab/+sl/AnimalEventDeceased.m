%{
# mouse has left the house

event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

cause = NULL : enum('sacrificed not needed','sacrificed for experiment','other','unknown') #cause of death

unique index (animal_id)
notes: varchar(256)                  # anything
%}

classdef AnimalEventDeceased < sl.AnimalEvent & dj.Manual
    methods(Static)
        function animals = living()
            animals = sl.Animal() - sl.AnimalEventDeceased();
        end
    end
        
    methods(Access=public)
        function s = printEvent(self)
            eventStruct = fetch(self,'*');
            if isempty(eventStruct.notes)
                notes = '';
            else
                notes = sprintf('(%s)',eventStruct.notes);
            end
            s = sprintf('%s %s: Animal %d deceased. Cause: %s. User: %s%s', ...
                eventStruct.date,...
                eventStruct.time,...
                eventStruct.animal_id,...
                eventStruct.cause,...
                eventStruct.user_name,...
                notes);
        end
    end
    
end

