%{
event_id : int unsigned AUTO_INCREMENT     # unique event id
---
-> sln_animal.Animal
-> sl.User
date                           : date
time = NULL                    : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
notes = NULL : varchar(256)                # notes about the event

%}
classdef AnimalEvent < dj.Shared
end

%TODO: nullable time field here, or non-nullable per event?