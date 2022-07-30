%{
#Task completed
-> sln_tissue.Task
---
-> sln_lab.User
task_completion_notes = NULL : varchar(512) #notes about the task completion
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
%}

classdef TaskCompleted < dj.Manual
    
end