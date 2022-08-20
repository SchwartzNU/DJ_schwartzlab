%{
#Task aborted
-> sln_tissue.Task
-> sln_tissue.Tissue
---
-> sln_lab.User
reason : varchar(512) #reason this task was not completed
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
%}

classdef TaskAborted < dj.Manual
    
end