%{
# animal has switched houses

event_id : int unsigned auto_increment
---
-> sl.Animal
(moved_by) -> sl.User(name)                              # who did the move
date : date
cause = NULL : enum('weaning', 'set as breeder', 'experiment', 'crowding', 'other','unknown') #reason for move
notes = NULL : varchar(256)                                 # notes about the event
cage_number: int unsigned       # cage number mouse was moved to
%}


classdef AnimalEventMoveCage < sl.AnimalEvent & dj.Manual   
end
% move_from_cage_number: int unsigned          # from cage number
% move_to_
