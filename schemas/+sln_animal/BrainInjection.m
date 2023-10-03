%{
# brain injections
-> sln_animal.AnimalEvent
---
-> sln_animal.InjectionSubstance
-> sln_animal.BrainArea                     # targeted brain area
hemisphere: enum('Left', 'Right')    # left or right side
head_rotation : float                # degrees, if not straight down
coordinates: longblob                # 3 element vector of coordinates in the standard order (AP, ML, DV)
dilution: float                      # dilution of substance (or 0 if not applicable or non-diluted)
%}
classdef BrainInjection < dj.Manual

    properties        
        printStr = '%s %s: Animal %d had a brain injection of substance with id: %d dilluted 1:%d targeting the %s %s. Coordinates (AP,ML,DV,angle): [%0.2f, %0.2f, %0.2f, %0.2f]. Performed by %s. (%s)\n';
        printFields = {'date','time','animal_id','substance_id','dilution','hemisphere','target','coordinates','head_rotation','user_name','notes'};
    end

end
