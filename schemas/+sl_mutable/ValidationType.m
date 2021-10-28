%{
# RGC has data of some particular type, used in figuring out validation score
validation_data_type : varchar(64) # name of validation type
---
%}

classdef ValidationType < dj.Lookup
    
end
