%{
#A reference of Superior Colliculus (mouse) border from top-down v
postbreg_ap: int unsigned #unit: micron, distance from Bregma point in AP
---
medial_point:int unsigned #SC border to the medial side, unit micron
lateral_point: int unsigned #SC border to the lateral side, unit micron
%}

classdef SCborderTopdown < dj.Lookup
end