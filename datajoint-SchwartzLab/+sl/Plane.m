%{
orientation : varchar(32) # orientation of section, e.g. horizontal, coronal, axial
reference : varchar(32)   # location of '0' point, e.g. bregma, lambda, mid-saggital, front, etc. 

%}

classdef Plane < dj.Lookup
end