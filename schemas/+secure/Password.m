%{
# Passwords for database users or other things
account_name : varchar(128)
---
passwd : varchar(256) #the password
%}
classdef Password < dj.Lookup

end