%{
# brain injections
event_id : int unsigned auto_increment
---
-> sl.Animal
-> sl.InjectionSubstance
-> sl.User                          # who did the injection
-> sl.BrainArea                     # targeted brain area
hemisphere: enum('Left', 'Right')    # left or right side
date: date
time: time                           # time of 
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db

head_rotation : float                # degrees, if not straight down
coordinates: longblob                # 3 element vector of coordinates in the standard order (AP, ML, DV)
dilution: float                      # dilution of substance (or 0 if not applicable or non-diluted)
notes = NULL: varchar(256)           # surgery notes (can include people who assisted)

%}
classdef AnimalEventBrainInjection < sl.AnimalEvent & dj.Manual
    
     methods(Access=public)
        function s = printEvent(self)
            eventStruct = fetch(self,'*');
            if isempty(eventStruct.notes)
                notes = '';
            else
                notes = sprintf('(%s)',eventStruct.notes);
            end
            coords = eventStruct.coordinates;
            coords_str = sprintf('[%0.2f,%0.2f,%0.2f,%0.2f]', coords(1),coords(2),coords(3),eventStruct.head_rotation);
            
            s = sprintf('%s %s: Animal %d had a brain injection of %s dilluted 1:%d targeting the %s %s. Coordinates (AP,ML,DV,angle): %s. Performed by %s. %s', ...
                eventStruct.date,...
                eventStruct.time,...
                eventStruct.animal_id,...
                eventStruct.substance_name,...
                eventStruct.dilution,...
                eventStruct.hemisphere,...
                eventStruct.target,...
                coords_str,...
                eventStruct.user_name,...
                notes);
        end        
    end

    
end
