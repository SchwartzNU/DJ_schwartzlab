%{
#Macro is a tree of tasks
macro_name : varchar(128) 
---
tissue_type : enum('Retina', 'Brain') #type of tissue
task_tree : blob #serialized tree structure for tasks using hlp_serialize
%}

classdef Macro < dj.Manual
    
end