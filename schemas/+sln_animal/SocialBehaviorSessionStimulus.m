%{
-> sln_animal.SocialBehaviorSession   # the session, defined by the central mouse
arm : enum('A', 'B', 'C')            # location of the stimulus in the arena
---
-> sl_behavior.VisualStimulusType #kind of stimmulus, e.g., novel object, pups, cagemate, etc
(stimulus_animal_id) -> [nullable] sln_animal.Animal(animal_id) # the animal in this arm
%}

classdef SocialBehaviorSessionStimulus < dj.Part
    properties (SetAccess = protected)
        master = sln_animal.SocialBehaviorSession
    end
    
end