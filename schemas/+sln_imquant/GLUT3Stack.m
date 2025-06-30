%{
# GLUT3Stack
-> sln_animal.Eye
image_fname : varchar(128)
---
age_at_exp : float
-> sln_imquant.LightCondition
-> sln_imquant.DrugCondition
stim_on_time = 0 : float #time stimulus was on
stim_off_time = 0 : float #time stimulus was off after it was on
notes = NULL : varchar(512)
%}
classdef GLUT3Stack < dj.Manual
    methods(Static)

    end
end