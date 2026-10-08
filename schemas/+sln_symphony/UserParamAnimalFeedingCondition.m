%{
# UserParamAnimalFeedingCondition
-> `sln_animal`.`animal`
---
feeding_condition=null      : enum('chow','HFD_8w','HFD','HFD_16w','FR','OvernightStarvation') # 
%}
classdef UserParamAnimalFeedingCondition < dj.Manual
end
