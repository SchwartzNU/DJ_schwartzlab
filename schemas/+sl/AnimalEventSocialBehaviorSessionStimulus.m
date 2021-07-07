%{
-> sl.AnimalEventSocialBehaviorSession   # the session, defined by the central mouse
arm : enum('A', 'B', 'C')            # location of the stimulus in the arena
---
-> sl.BehaviorVisualStimulusType #kind of stimmulus, e.g., novel object, pups, cagemate, etc
(stimulus_animal_id) -> [nullable] sl.Animal(animal_id) # the animal in this arm
%}

classdef AnimalEventSocialBehaviorSessionStimulus < dj.Part
    properties (SetAccess = protected)
        master = sl.AnimalEventSocialBehaviorSession
    end

end