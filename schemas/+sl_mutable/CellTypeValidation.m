%{
# CellType validation data
-> sl.MeasuredCell
---
external_validation = 'F'   : enum('T','F')
validation_type  = 'none'   : enum('none','2P image', 'confocal image', 'soma size', 'whole-cell recording', 'transgenic line')
%}

classdef CellTypeValidation < dj.Manual
    
end
