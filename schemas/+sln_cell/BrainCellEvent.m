%{
event_id : int unsigned AUTO_INCREMENT     # unique event id
---
-> sln_cell.BrainCell
-> sln_lab.User
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
notes = NULL : varchar(256)                # notes about the event

%}
classdef BrainCellEvent < dj.Shared
    methods
        function stripped_key = insert(self, key)
            %strip extra fields
            stripped_key = key;
            ce_key = key;
            ce_fields = sln_cell.BrainCellEvent().header.names;

            f = fieldnames(key);
            for i=1:length(f)   
                if ismember(f{i}, ce_fields)
                    stripped_key = rmfield(stripped_key, f{i});
                else
                    ce_key = rmfield(ce_key, f{i});
                end
            end
            %ce_key
            insert@dj.Shared(self, ce_key);
            this_event_id = max(fetchn(sln_cell.BrainCellEvent, 'event_id'));
            stripped_key.event_id = this_event_id;
        end

    end
end

