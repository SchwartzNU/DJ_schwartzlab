%{
# Temp Filter table for functional filtering
-> sl.Epoch     # epoch this entry is for
---
passed=1: tinyint unsigned  # 0 for failed, 1 for passed
%}

classdef TempFilter < dj.Manual
    
end