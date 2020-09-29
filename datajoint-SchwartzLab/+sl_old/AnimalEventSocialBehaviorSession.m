%{
# Session in 3 chamber circular social behavior device. Animal here is the TEST (center) animal
event_id : int unsigned auto_increment
--- 
-> sl.Animal
(experimenter) -> sl.User(name)                      # who did it
recorded = 'F': enum('T','F')                        # was video recorded
fname = NULL : varchar(128)                          # root filename if session was recorded
date: date
session_start_time : time                            # session start time
duration_mins : smallint unsigned                    # approximate duration (minutes)
notes : varchar(256)                                 # notes about the animal's state and comfort level, other people involvd, etc. 
(purpose) -> sl.SocialBehaviorExperimentType(name)      # type of experiment, like social dominance, mate preference familiarity with rig, etc.  
%}

classdef AnimalEventSocialBehaviorSession < sl.AnimalEvent & dj.Manual 
    
end
