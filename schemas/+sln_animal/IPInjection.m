%{
# IP injections
-> sln_animal.AnimalEvent
---
-> sln_animal.InjectionSubstance
concentration: float                      # mL / kg
%}
classdef IPInjection < dj.Manual

    properties        
        printStr = '%s %s: Animal %d had an IP injection of substance with id: %d at concentration %d. Performed by %s. (%s)\n';
        printFields = {'date','time','animal_id','substance_id','concentration','user_name','notes'};
    end

end
