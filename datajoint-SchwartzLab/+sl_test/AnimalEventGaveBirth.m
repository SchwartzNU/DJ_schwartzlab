%{
# babies!
event_id : int unsigned auto_increment
---
-> sl_test.Animal
number_of_pups : tinyint unsigned                    # how many babies
date : date
time = NULL : time    #unlikely to be recorded, but all events should have a time field

entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

notes: varchar(128)                                  # anything
%}

classdef AnimalEventGaveBirth < sl_test.AnimalEvent & dj.Manual
    methods(Access=public)
        function s = printEvent(self)
            eventStruct = fetch(self,'*');
            if isempty(eventStruct.notes)
                notes = '';
            else
                notes = sprintf('(%s)',eventStruct.notes);
            end
            s = sprintf('%s: Animal %d gave birth to %d pups. %s', ...
                eventStruct.date,...
                eventStruct.animal_id,...
                eventStruct.number_of_pups,...
                notes);
        end
    end
end

