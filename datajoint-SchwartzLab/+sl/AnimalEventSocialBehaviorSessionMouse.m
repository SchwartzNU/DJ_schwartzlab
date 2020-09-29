%{
-> sl.AnimalEventSocialBehaviorSession   # the session, defined by the central mouse
arm : enum('A', 'B', 'C')            # location of the mouse in the arena
---
(stimulus_mouse) -> sl.Animal(animal_id) # the animal in this arm

unique index (stimulus_mouse)
%}

classdef AnimalEventSocialBehaviorSessionMouse < dj.Part
    properties (SetAccess = protected)
        master = sl.AnimalEventSocialBehaviorSession
    end

end
