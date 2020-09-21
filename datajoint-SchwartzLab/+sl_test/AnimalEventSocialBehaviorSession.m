%{
# Session in 3 chamber circular social behavior device. Animal here is the TEST (center) animal
-> sl_test.AnimalEvent                               # includes date of session
--- 
(experimenter) -> sl_test.User(name)                 # who did it
recorded : tinyint unsigned                          # 0 = false or 1 = true
fname : varchar(128)                                 # root filename if session was recorded
session_time : time                                  # session time
duration_mins : smallint unsigned                    # approximate duration (minutes)
notes : varchar(256)                                 # notes about the animal's state and comfort level, other people involvd, etc. 
(purpose) -> SocialBehaviorExperimentType(name)      # type of experiment, like social dominance, mate preference familiarity with rig, etc.  
%}

classdef AnimalEventSocialBehaviorSession < dj.Part
     properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end
