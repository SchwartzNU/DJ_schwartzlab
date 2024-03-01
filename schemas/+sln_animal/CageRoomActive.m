%{
# cage room that is active
room_number                 : varchar(16)                   # room number
%}
classdef CageRoomActive < dj.Lookup
    properties
        contents = {'In Lab', 'SB-237', 'SB-419','QB-802', 'W-188'}';
    end
end
