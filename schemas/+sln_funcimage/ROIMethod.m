%{
# ROI detection method
method_id                   : int unsigned AUTO_INCREMENT #unique ID for method 
---
method_name                 : varchar(256)
notes    = null             : varchar(512)
%}

classdef ROIMethod < dj.Manual
end