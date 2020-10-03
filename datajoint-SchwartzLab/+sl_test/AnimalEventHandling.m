%{
# just handling mice to get them used to humans
event_id:int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User # handler
date:date
time:time
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db
duration:time # approximate duration

notes = NULL:varchar(256) # notes about the animal's state and comfort level
%}

classdef AnimalEventHandling < sl_test.AnimalEvent & dj.Manual

    properties
        printStr = '%s %s: Animal %d handled by %s for %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'user_name', 'duration', 'notes'};
    end

    methods (Access = public)

        function s = printEvent(self)
            eventStruct = fetch(self, '*');

            if isempty(eventStruct.notes)
                notes = '';
            else
                notes = sprintf('(%s)', eventStruct.notes);
            end

            s = sprintf('%s %s: Animal %d handled by %s for %s. %s', ...
                eventStruct.date, ...
                eventStruct.time, ...
                eventStruct.animal_id, ...
                eventStruct.user_name, ...
                eventStruct.duration, ...
                notes);
        end

    end

end
