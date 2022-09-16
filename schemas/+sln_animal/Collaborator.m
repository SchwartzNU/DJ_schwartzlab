%{
# A collaborating lab
-> sln_animal.Source
---
lab_name                    : varchar(64)                   # 
organization                : varchar(64)                   # 
%}

classdef Collaborator < dj.Manual
    methods(Static)
        function q = active()
            q = sln_animal.Collaborator & sln_animal.CollaboratorActive;
        end

        function q = inactive()
            q = sln_animal.Collaborator - sln_animal.CollaboratorActive;
        end
    end

    methods 
        function activate(self)
            insert(sln_animal.CollaboratorActive,fetch(self));
        end

        function deactivate(self)           
            delQuick(sln_animal.CollaboratorActive & fetch(self));
        end
    end
end

