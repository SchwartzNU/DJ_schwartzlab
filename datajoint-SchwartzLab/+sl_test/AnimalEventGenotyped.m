%{
# animal genotyped
event_id : int unsigned auto_increment
---
-> sl_test.Animal
-> sl_test.User                          # who did the genotyping
date : date
time = NULL : time
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

notes = NULL : varchar(256)                                 # notes about the event
genotype_status : enum('het', 'homo', 'non-carrier', 'carrier', 'unknown')  # positive means positive for multiple genes if double or triple trans., het or homo only if we know 
%}

classdef AnimalEventGenotyped < sl_test.AnimalEvent & dj.Manual
    methods(Access=public)
        function s = printEvent(self)
                eventStruct = fetch(self,'*');
                if isempty(eventStruct.notes)
                    notes = '';
                else
                    notes = sprintf('(%s)',eventStruct.notes);
                end                
                s = sprintf('%s: %s: Animal %d genotyped by %s. Result: %s%s', ...
                    eventStruct.date,...
                    eventStruct.time,...
                    eventStruct.animal_id,...
                    eventStruct.user_name,...
                    eventStruct.genotype_status,...
                    notes);                    
        end
    end
end

