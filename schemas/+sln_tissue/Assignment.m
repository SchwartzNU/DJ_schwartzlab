%{
#Assignments of macros to tissues
-> sln_tissue.Tissue
-> sln_tissue.Macro
---
-> [nullable] sln_lab.Project
entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
%}

classdef Assignment < dj.Manual
    
end