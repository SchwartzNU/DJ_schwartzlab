%{
# Single annotation of a behavioral video
->sln_animal.SocialBehaviorSession
->sl_behavior.AnnotationType
frame : int unsigned          #frame number
---
modifier = NULL : varchar(32)   # modifier value or NULL if there is none
duration = NULL : smallint      # duration of the state event in frames (NULL for point events)
%}
classdef Annotation < dj.Manual
    
end