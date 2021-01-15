%{
# animal assigned to animal protocol

event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

notes = NULL : varchar(256)                                 # notes about the event

-> sl.AnimalProtocol
%}


classdef AnimalEventAssignProtocol < sl.AnimalEvent & dj.Manual
    properties
        printStr = '%s: Animal %d assigned to protocol "%s". User: %s. (%s)\n';
        printFields = {'date','animal_id','protocol_name','user_name','notes'};
    end

    methods(Static)
        function protocol_number = current()
            protocol_number = sl.AnimalEventAssignProtocol() & 'LIMIT 1 PER animal_id DESC';
        end

        function protocol_number = initial()
            protocol_number = sl.AnimalEventAssignProtocol() & 'LIMIT 1 PER animal_id ASC';
        end
    end
    
end
