%{
# User: Active lab member
->sl.User
---
%}
classdef UserActive < dj.Part
    properties(SetAccess=protected)
        master = sl.User
    end
end
