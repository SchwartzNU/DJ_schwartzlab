%{
# IP injection of tamoxifen or some other substance
event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.InjectionSubstance
inject_time: time                    # time of day
date : date
concentration: float                 # mg per Kg body weight
notes = NULL : varchar(256)          # notes about the event
(injected_by) -> sl.User(name)  # who did the injection
%}

classdef AnimalEventIPinjection < sl.AnimalEvent & dj.Manual   

end
