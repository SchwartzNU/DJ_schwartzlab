%{
# animal assigned to animal protocol

-> sln_animal.AnimalEvent
---
-> sln_animal.AnimalProtocol
%}


classdef AssignProtocol < dj.Manual
    properties
        printStr = '%s: Animal %d assigned to protocol "%s". User: %s. (%s)\n';
        printFields = {'date','animal_id','protocol_name','user_name','notes'};
    end

    methods(Static)
        function protocol_number = current()
            protocol_number = sln_animal.AnimalEvent * sln_animal.AssignProtocol & 'LIMIT 1 PER animal_id ORDER BY date DESC';
        end

        function protocol_number = initial()
            protocol_number = sln_animal.AnimalEvent * sln_animal.AssignProtocol & 'LIMIT 1 PER animal_id ORDER BY date ASC';
        end
    end
    
end
