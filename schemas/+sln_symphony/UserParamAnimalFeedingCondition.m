%{
# UserParamAnimalFeedingCondition
-> sln_animal.Animal
---
feeding_condition = NULL : enum('chow', 'HFD', 'FR') # 
%}
classdef UserParamAnimalFeedingCondition < dj.Manual
end
