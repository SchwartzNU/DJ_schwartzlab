%{
# User: Active lab member
->sl_test.User
---
%}
classdef UserActive < dj.Part
    properties(SetAccess=protected)
        master = sl_test.User
    end
end