%{
# animal has switched houses

event_id : int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

cause = NULL : enum('weaning', 'set as breeder', 'experiment', 'crowding', 'other','unknown') #reason for move
notes = NULL : varchar(256)                                 # notes about the event

cage_number: int unsigned       # cage number mouse was moved to
%}


classdef AnimalEventMoveCage < sl_test.AnimalEvent & dj.Manual   
end
% move_from_cage_number: int unsigned          # from cage number
% move_to_