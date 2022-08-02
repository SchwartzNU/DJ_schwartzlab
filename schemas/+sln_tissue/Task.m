%{
#Task to be preformed on tissue
-> sln_tissue.Tissue
task_name : varchar(128) 
---
task_type : varchar(64) # name of the referencing table
task_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
%}

classdef Task < dj.Shared
    
end