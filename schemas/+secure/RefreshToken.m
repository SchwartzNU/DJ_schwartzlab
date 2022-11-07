%{
# Refresh token for a google calendar
token_id : int unsigned AUTO_INCREMENT   # unique token id
-> secure.GcalConnection
---
token : varchar(256) #the token
%}
classdef RefreshToken < dj.Manual

end

