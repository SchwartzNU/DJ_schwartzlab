%{
#A reference of Superior Colliculus (mouse) border from top-down v
postbreg_ap: int unsigned #unit: micron, distance from Bregma point in AP
---
medial_point:float #SC border to the medial side
lateral_point: float #SC border to the lateral side
%}

classdef SCborderTopdown < dj.Lookup
end