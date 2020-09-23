%{
# animal has switched houses
-> sl_test.AnimalEvent                       # includes date the move occurred
---
cage_number: int unsigned            # cage number mouse was moved to
cause = NULL : enum('weaning', 'set as breeder', 'experiment', 'crowding', 'other','unknown')     # cause of move
(moved_by) -> sl_test.User(name)             # who did the move (we can have a User entry for CCM staff)
%}

classdef AnimalEventMoveCage < sl_test.EventLog & dj.Part    
    properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end 
end
% move_from_cage_number: int unsigned          # from cage number
% move_to_