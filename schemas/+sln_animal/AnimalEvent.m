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
            if nargout
                stripped_key = key;
            end
            ae_fields = sln_animal.AnimalEvent().header.names;

            f = fieldnames(key);
            for i=1:length(f)   
                if ismember(f{i}, ae_fields)
                    if nargout && ~strcmp(f{i}, 'event_id')
                        stripped_key = rmfield(stripped_key, f{i});
                    end
                else
                    key = rmfield(key, f{i});
                end
            end

            insert@dj.Shared(self, key);
            
            if nargout && ~ismember('event_id',f)
                event_ids = num2cell(fetchn(sln_animal.AnimalEvent & key, 'event_id'));
                [stripped_key(:).event_id] = event_ids{:};
            end
        end

    end
end

%TODO: nullable time field here, or non-nullable per event?