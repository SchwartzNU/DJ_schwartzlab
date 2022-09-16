%{
# cage room 
room_number: varchar(16)      # room number
---
%}
classdef CageRoom < dj.Lookup
    properties
        contents = {'SB-237', 'SB-419', 'SB-443', 'SB-455','QB-802'}';
    end
end