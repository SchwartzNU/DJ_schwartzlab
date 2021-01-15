%{
# Analysis Pipeline
pipeline_name: varchar(64) # name of this pipeline
---
pipeline_description = NULL: varchar(512) # more detailed description of the purpose
(owner)->sl.User(user_name)
%}

classdef Pipeline < dj.Manual
    
end