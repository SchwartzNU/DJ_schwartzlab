%{
# eye sutures
-> sln_animal.AnimalEvent
---
side: enum('Left', 'Right')          # left, right
%}

classdef EyeSuture < dj.Manual
        
    properties
        printStr = '%s %s: Animal %d had a %s eye suture, performed by %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'side', 'user_name', 'notes'};
    end
    
end
