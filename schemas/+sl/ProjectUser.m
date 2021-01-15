%{
# key users associated with a project

-> sl.Project
-> sl.User

%}

classdef ProjectUser < dj.Part
    properties (SetAccess = protected)
        master = sl.Project;
    end

end
