%{
-> sl_test.AnimalEventSocialBehaviorSession   # the session, defined by the central mouse
(experimenter) -> sl_test.User(name)                 # who did it

%}

classdef AnimalEventSocialBehaviorSessionExperimenter < dj.Part

    properties (SetAccess = protected)
        master = sl_test.AnimalEvent
    end

end
