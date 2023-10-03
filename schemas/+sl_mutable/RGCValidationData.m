%{
# RGC has data of some particular type, used in figuring out validation score
-> sl.MeasuredCell
-> sl_mutable.ValidationType
---
score  =  'none' : enum('none', 'low', 'medium', 'high')
extra_info = NULL : varchar(64) # additional information like which line, etc
%}

classdef RGCValidationData < dj.Manual
    
end
