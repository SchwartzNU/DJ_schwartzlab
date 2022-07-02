%{
# eye injections
-> sln_animal.AnimalEvent
---
-> sln_animal.InjectionSubstance
-> sln_animal.Eye
dilution: float                      # dilution of substance
%}

classdef EyeInjection < dj.Manual
        
    properties
        printStr = '%s %s: Animal %d had a %s eye injection of substancce with id: %d, dilluted 1:%d, performed by %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'side', 'substance_id', 'dilution', 'user_name', 'notes'};
    end
    
end
