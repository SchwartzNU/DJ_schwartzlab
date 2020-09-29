%{
# Social behavior experiment type
purpose : varchar(32)                  # type of experiment, like social dominance, mate preference familiarity with rig, etc.
---
description : varchar(128)          # longer description
%}
classdef SocialBehaviorExperimentType < dj.Lookup
    
end