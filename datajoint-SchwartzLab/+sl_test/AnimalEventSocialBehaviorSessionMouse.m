%{
-> sl_test.AnimalEventSocialBehaviorSession   # the session, defined by the central mouse
-> sl_test.Animal                             # the animal this entry refers to
---
[unique] arm : enum('A', 'B', 'C')            # location of the mouse in the arena

%}

classdef AnimalEventSocialBehaviorSessionMouse < dj.Part

    properties (SetAccess = protected)
        master = sl_test.AnimalEvent
    end

end
