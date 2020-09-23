%{
# mouse has left the house

event_id : int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User
date : date
time = NULL : time
cause = NULL : enum('sacrificed not needed','sacrificed for experiment','other','unknown') #cause of death

unique index (animal_id)
%}

classdef AnimalEventDeceased < sl_test.AnimalEvent & dj.Manual
end

