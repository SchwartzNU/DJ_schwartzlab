%{
# Behavior Visual Stimulus Type
stim_type : varchar(64)      # e.g. novel object, pups, single pup
---
needs_id : enum('T', 'F') # need an animal ID
description = NULL : varchar(128)          # longer description
%}
classdef BehaviorVisualStimulusType < dj.Lookup
    
end