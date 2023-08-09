%{
# cage room
room_number                 : varchar(16)                   # room number
%}
classdef CageRoom < dj.Lookup
    properties
        contents = {'In Lab', 'SB-237', 'SB-419', 'SB-443', 'SB-455','QB-802', 'W-188}';
    end
end
