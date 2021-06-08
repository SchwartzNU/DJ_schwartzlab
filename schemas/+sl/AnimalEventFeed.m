%{
# Feed with some substance other than normal food
event_id:int unsigned auto_increment
---
-> sl.Animal
-> sl.InjectionSubstance # in this case not really an injection substance
-> sl.User # who did the feed
date:date
time:time # time of day
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

notes = NULL:varchar(256) # notes about the event
%}

classdef AnimalEventFeed < sl.AnimalEvent & dj.Manual

    properties
        printStr = '%s %s: Animal %d fed with a substance with id: %d, performed by %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'substance_id', 'user_name', 'notes'};
    end

end
