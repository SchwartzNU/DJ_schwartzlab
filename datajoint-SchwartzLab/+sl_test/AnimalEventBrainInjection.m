%{
# brain injections
(inject_date) -> sl_test.AnimalEvent(date)
---
-> sl_test.InjectionSubstance
(target) -> sl_test.BrainArea(name)  # brain area targeted
hemisphere: enum('L', 'R')           # left or right side
inject_time: time                    # time of day
head_rotation : float                # degrees, if not straight down
coordinates: longblob                # 3 element vector of coordinates in the standard order (AP, ML, DV)
dilution: float                      # dilution of substance (or 0 if not applicable or non-diluted)
notes = NULL: varchar(256)           # surgery notes (can include people who assisted)
(injected_by) -> sl_test.User(name)  # who did the injection
%}

classdef AnimalEventBrainInjection < dj.Part
    properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end
