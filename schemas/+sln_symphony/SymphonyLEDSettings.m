%{
# A group of settings for Stage protocols
-> sln_symphony.SymphonyEpochBlock
-> sln_symphony.LED
---
value : tinyint unsigned
%}
classdef SymphonyLEDSettings < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Symphony;
end
end