%{
#A list of lab projects  
project_name : varchar(32)  #what is the project called?
---
description = NULL : varchar(512)    # explanation of this project
%}

classdef Project < dj.Lookup
    methods(Static)
        function q = active()
            q = sln_lab.Project & sln_lab.ProjectActive;
        end

        function q = inactive()
            q = sln_lab.Project - sln_lab.ProjectActive;
        end
    end

    methods
        function activate(self)
            insert(sln_lab.ProjectActive,fetch(self));
        end

        function deactivate(self)
            delQuick(sln_lab.ProjectActive & fetch(self));
        end
    end
end