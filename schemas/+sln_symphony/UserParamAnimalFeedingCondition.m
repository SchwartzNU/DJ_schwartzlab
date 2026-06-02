%{
# UserParamAnimalFeedingCondition
-> sln_animal.Animal
---
feeding_condition=null      : enum('chow','HFD','FR', 'OvernightStarvation')       # 
%}
classdef UserParamAnimalFeedingCondition < dj.Manual
end
