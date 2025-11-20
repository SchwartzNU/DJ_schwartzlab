%{
#Queries for particular projects / users
query_name                   : varchar(128)   # unique name
-> sln_lab.User
---
-> [nullable] sln_lab.Project
sql_query : varchar(4096)
%}

classdef Query < dj.Manual
    methods(Static)
    end
end