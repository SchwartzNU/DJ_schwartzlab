%{
# Cell assigned to type

event_id : int unsigned auto_increment
---
-> sl.MeasuredCell
-> sl.User
-> sl.CellType
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
notes = NULL : varchar(256)    # notes about the event
%}


classdef CellEventAssignType <  sl.CellEvent & dj.Manual 
    properties
        printStr = '%s: Cell %d assigned to class %s, type %s. User: %s. (%s)\n';
        printFields = {'entry_time','cell_unid','cell_class','name_full','user_name','notes'};
    end

    methods(Static)
        function cellType = current()
            cellType = sl.CellEventAssignType() & 'LIMIT 1 PER cell_unid DESC';
        end
    end
    
end
