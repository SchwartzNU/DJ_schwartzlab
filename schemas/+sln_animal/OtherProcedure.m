%{
# other procedure
-> sln_animal.AnimalEvent
---
procedure_name: varchar(128)         # name of the procedure
%}

classdef OtherProcedure < dj.Manual
        
    properties
        printStr = '%s %s: Animal %d had a procedure named %s, performed by %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'procedure_name', 'user_name', 'notes'};
    end
    
end
