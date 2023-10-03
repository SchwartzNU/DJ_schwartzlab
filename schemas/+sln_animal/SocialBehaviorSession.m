%{
# Session in 3 chamber circular social behavior device. Animal here is the TEST (center) animal

-> sln_animal.AnimalEvent
---
-> sl_behavior.SocialBehaviorExperimentType # type of experiment, like social dominance, mate preference familiarity with rig, etc.
-> sl_behavior.TestAnimalType # type of the test animal
recorded = 'F':enum('T', 'F') # was session recorded

%}

classdef SocialBehaviorSession < dj.Manual

    properties
        printStr = '%s %s: Animal %d had a social behavior session of type "%s". Performed by %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'purpose', 'user_name', 'notes'};
    end

end
