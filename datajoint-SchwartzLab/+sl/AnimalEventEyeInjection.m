%{
# eye injections
-> sl.AnimalEvent 
---
-> sl.InjectionSubstance
-> sl.Eye
inject_time: time                    # time of day
dilution: float                      # dilution of substance
notes: varchar(256)                  # injection notes (can include people who assisted)
(injected_by) -> sl.User(name)       # who did the injection
%}

classdef AnimalEventEyeInjection < dj.Part
    properties(SetAccess=protected)
        master = sl.AnimalEvent
    end
end
