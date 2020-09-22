%{
# brain injections
-> sl.AnimalEvent
---
-> sl.InjectionSubstance
(target) -> sl.BrainArea(name)  # brain area targeted
hemisphere: enum('Left', 'Right')           # left or right side
inject_time: time                    # time of day
head_rotation : float                # degrees, if not straight down
coordinates: longblob                # 3 element vector of coordinates in the standard order (AP, ML, DV)
dilution: float                      # dilution of substance (or 0 if not applicable or non-diluted)
notes = NULL: varchar(256)           # surgery notes (can include people who assisted)
(injected_by) -> sl.User(name)  # who did the injection
%}

classdef AnimalEventBrainInjection < dj.Part
    properties(SetAccess=protected)
        master = sl.AnimalEvent
    end
end
