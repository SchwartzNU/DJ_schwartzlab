%{
# animal genotyped
event_id:int unsigned auto_increment
---
-> sl.Animal
-> sl.User # who did the genotyping
date:date
time = NULL:time
entry_time = CURRENT_TIMESTAMP:timestamp # when this was entered into db

notes = NULL:varchar(256) # notes about the event
genotype_status:enum('het', 'homo', 'non-carrier', 'carrier', 'unknown') # positive means positive for multiple genes if double or triple trans., het or homo only if we know
%}

classdef AnimalEventGenotyped < sl.AnimalEvent & dj.Manual

    properties
        printStr = '%s: %s: Animal %d genotyped by %s. Result: %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'user_name', 'genotype_status', 'notes'};
    end

end
