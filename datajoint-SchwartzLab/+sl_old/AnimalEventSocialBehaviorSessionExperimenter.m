%{
-> sl.AnimalEventSocialBehaviorSession   # the session, defined by the central mouse
(experimenter) -> sl.User(name)                 # who did it

%}

classdef AnimalEventSocialBehaviorSessionExperimenter < dj.Part

    properties (SetAccess = protected)
        master = sl.AnimalEvent
    end

end
