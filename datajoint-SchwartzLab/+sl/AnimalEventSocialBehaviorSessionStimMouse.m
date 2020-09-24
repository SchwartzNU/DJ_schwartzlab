%{
# Stimulus mouse in an arm of the behavior rig 
-> sl.AnimalEventSocialBehaviorSession   # the session, defined by the central mouse
(stim_mouse) -> sl.Animal(animal_id)
---
arm : enum('A', 'B', 'C')            # location of the mouse in the arena
%}

classdef AnimalEventSocialBehaviorSessionStimMouse < sl.AnimalEvent & dj.Part

    properties (SetAccess = protected)
        master = sl.AnimalEventSocialBehaviorSession
    end

end
