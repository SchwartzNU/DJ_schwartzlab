%{
# brain injections
event_id : int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.InjectionSubstance
-> sl_test.User                          # who did the injection
-> sl_test.BrainArea                     # targeted brain area
hemisphere: enum('Left', 'Right')    # left or right side
date: date
time: time                           # time of 
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

head_rotation : float                # degrees, if not straight down
coordinates: longblob                # 3 element vector of coordinates in the standard order (AP, ML, DV)
dilution: float                      # dilution of substance (or 0 if not applicable or non-diluted)
notes = NULL: varchar(256)           # surgery notes (can include people who assisted)

%}
classdef AnimalEventBrainInjection < dj.Manual
end
