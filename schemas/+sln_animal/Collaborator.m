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
            q = sln_animal.Collaborator & sln_animal.CollaboratorStrainActive;
        end

        function q = inactive()
            q = sln_animal.Collaborator - sln_animal.CollaboratorStrainActive;
        end
    end
end

