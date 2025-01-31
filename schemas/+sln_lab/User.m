%{
# User: Lab member
user_name                   : varchar(32)                   # Lab member name
---
user_name_for_var           : varchar(32)                   # short version with no spaces or punctuation for a variable name
net_id=null                 : varchar(16)                   # northwestern netid
%}
classdef User < dj.Lookup
    
end
