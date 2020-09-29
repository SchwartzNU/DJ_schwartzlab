%{
-> sl_test.AnimalEventSocialBehaviorSession   # the session, defined by the central mouse
arm : enum('A', 'B', 'C')            # location of the mouse in the arena
---
(stimulus_mouse) -> sl_test.Animal(animal_id) # the animal in this arm

unique index (stimulus_mouse)
%}

classdef AnimalEventSocialBehaviorSessionStimMouse < dj.Part
    properties (SetAccess = protected)
        master = sl_test.AnimalEventSocialBehaviorSession
    end

end
