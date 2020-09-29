%{
# User: Lab member
user_name : varchar(32)                  # Lab member name
---
user_name_for_var : varchar(32)     # short version with no spaces or punctuation for a variable name
password = NULL: varchar(32)        # login password (Users with NULL pwd cannot login)
%}
classdef User < dj.Lookup
    
end