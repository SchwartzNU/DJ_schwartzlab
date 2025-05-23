%{
# Assign cage to room
-> sln_animal.Cage
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
---
-> sln_animal.CageRoom
-> sln_lab.User
date                           : date # date cage was moved
%}

classdef CageAssignRoom < dj.Manual
    methods(Static)
        function cage = current()
            cage = sln_animal.CageAssignRoom & 'LIMIT 1 PER cage_number ORDER BY date DESC, entry_time DESC';
        end

        function cage = initial()
            cage = sln_animal.CageAssignRoom & 'LIMIT 1 PER cage_number ORDER BY date ASC, entry_time ASC';
        end
    end
end