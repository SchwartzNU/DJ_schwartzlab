%{
# key users associated with a project

-> sl_test.Project
-> sl_test.User

%}

classdef ProjectUser < dj.Part
    properties (SetAccess = protected)
        master = sl_test.Project;
    end

end
