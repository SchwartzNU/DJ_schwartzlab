%{
# eye injections
event_id : int unsigned auto_increment
---
-> sl.InjectionSubstance
-> sl.Eye
inject_time: time                    # time of day
date : date
dilution: float                      # dilution of substance
notes: varchar(256)                  # injection notes (can include people who assisted)
(injected_by) -> sl.User(name)  # who did the injection
%}

classdef AnimalEventEyeInjection < sl.AnimalEvent & dj.Manual   
end
