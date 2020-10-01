%{
# User: Lab member
user_name : varchar(32)                  # Lab member name
---
user_name_for_var : varchar(32)     # short version with no spaces or punctuation for a variable name
password : varchar(32)              # will remove this, just need it now to test the app
%}
classdef User < dj.Lookup
    
end