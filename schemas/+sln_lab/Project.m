%{
#A list of lab projects  
project_name : varchar(32)  #what is the project called?
---
description = NULL : varchar(512)    # explanation of this project
%}

classdef Project < dj.Lookup
end