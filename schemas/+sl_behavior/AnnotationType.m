%{
# Annotation type (from BORIS)
annotation_name : varchar(64)   # name of the annotation
---
type : enum('point', 'state')   #single point or state
has_modifier: enum('T', 'F')    #whether this annotation has a modifier 
description : varchar(128)          # description of how this is marked by the user
%}
classdef AnnotationType < dj.Lookup
    
end