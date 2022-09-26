%{
# Connection to a google calendar
connection_name : varchar(32) #name of connection
---
refresh_url : varchar(512) #url to get refresh token 
client_id : varchar(128) 
client_secret : varchar(128) 
%}
classdef GcalConnection < dj.Manual

end