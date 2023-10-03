%{
# Animal protocol
protocol_name = 'NULL': varchar(256)     # name in eacuc.northwestern.edu
---
protocol_number: int unsigned 
%}

classdef AnimalProtocol < dj.Manual
    properties
        isActive = true;
    end
end

% We can make a part table for active protocols or just a Matlab property
% maybe