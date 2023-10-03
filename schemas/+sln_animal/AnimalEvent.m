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
        function [stripped_key,animal_ids] = insert(self, key)
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
            
            if ~ismember('event_id', f)
                next_id = self.schema.conn.query('select max(event_id)+1 as next from sln_animal.animal_event').next;
                next_ids = num2cell(double(next_id) + (1:numel(key)));
                [key(:).event_id] = next_ids{:};
            end

            insert@dj.Shared(self, key);
            
            if nargout && ~ismember('event_id',f)
                [stripped_key(:).event_id] = next_ids{:};
            end
            if nargout
                animal_ids = [key.animal_id];
            end
            
        end

    end
end

%TODO: nullable time field here, or non-nullable per event?