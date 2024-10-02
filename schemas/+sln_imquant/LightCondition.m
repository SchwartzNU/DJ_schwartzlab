%{
# LightCondition
light_condition_name : varchar(64)
---
notes = NULL : varchar(256) # description of condition 
%}
classdef LightCondition < dj.Lookup
    methods(Static)

    end
end