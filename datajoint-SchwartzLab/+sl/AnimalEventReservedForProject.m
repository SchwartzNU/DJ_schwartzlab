%{
# for associating an animal with a project, used to prevent conflicting reservations

event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.Project
-> sl.User           #who made the reservation
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

notes = NULL : varchar(256)                                 # notes about the event

%}


classdef AnimalEventReservedForProject < sl.AnimalEvent & dj.Manual
     methods(Access=public)
        function s = printEvent(self)
            eventStruct = fetch(self,'*');
            if isempty(eventStruct.notes)
                notes = '';
            else
                notes = sprintf('(%s)',eventStruct.notes);
            end
            s = sprintf('%s: Animal %d reserved for project "%s" by %s. %s', ...
                eventStruct.date,...
                eventStruct.animal_id,...
                eventStruct.project_name,...
                eventStruct.user_name,...
                notes);
        end
    end
end