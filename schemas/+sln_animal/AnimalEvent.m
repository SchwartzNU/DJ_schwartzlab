%{
event_id : int unsigned AUTO_INCREMENT     # unique event id
---
-> sln_animal.Animal
-> sln_lab.User
date                           : date
time = NULL                    : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
notes = NULL : varchar(256)                # notes about the event
%}
classdef AnimalEvent < dj.Shared
    methods
        function stripped_key = insert(self, key)
            %strip extra fields
            stripped_key = key;
            ae_key = key;
            ae_fields = sln_animal.AnimalEvent().header.names;

            f = fieldnames(key);
            for i=1:length(f)   
                if ismember(f{i}, ae_fields)
                    stripped_key = rmfield(stripped_key, f{i});
                else
                    ae_key = rmfield(ae_key, f{i});
                end
            end

            insert@dj.Shared(self, ae_key);
            this_event_id = max(fetchn(sln_animal.AnimalEvent, 'event_id'));
            stripped_key.event_id = this_event_id;
        end

    end
end

%TODO: nullable time field here, or non-nullable per event?