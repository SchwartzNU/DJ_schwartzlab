%{
#Note about this tissue
-> sln_tissue.Tissue
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
---
-> sln_lab.User #user who entered the note
note_text : varchar(256) #text of the note
%}

classdef Note < dj.Manual
    
end