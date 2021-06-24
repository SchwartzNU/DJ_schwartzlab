%{
# Test animal type
animal_type_name : varchar(32)      # e.g. dominant male, mother, submissive male
---
description : varchar(128)          # longer description
%}
classdef TestAnimalType < dj.Lookup
    
end