%{
# Set breeding pair to active, NOT an AnimalEvent
ev_id : int unsigned AUTO_INCREMENT     # unique event id, different set than for AnimalEvents
---
-> sln_animal.BreedingPair
-> sln_lab.User
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
notes = NULL : varchar(256)                # notes about the event
date                           : date

%}
classdef ActivateBreedingPair < dj.Manual
%     properties
%         printStr = '%s: Breeding pair %d moved to cage %s in room %s. Cause: %s. User: %s. (%s)\n';
%         printFields = {'date','animal_id','cage_number','room_number','cause','user_name','notes'};
%     end
end