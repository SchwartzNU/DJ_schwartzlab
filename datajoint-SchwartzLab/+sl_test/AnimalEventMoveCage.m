%{
# animal has switched houses

event_id : int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User
date : date
time = NULL : time
cause = NULL : enum('weaning', 'set as breeder', 'experiment', 'crowding', 'other','unknown') #reason for move

cage_number: int unsigned       # cage number mouse was moved to
%}


classdef AnimalEventMoveCage < sl_test.AnimalEvent & dj.Manual   
end
% move_from_cage_number: int unsigned          # from cage number
% move_to_