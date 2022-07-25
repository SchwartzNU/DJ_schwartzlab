%{
# A strain from a collaborating lab
-> sln_animal.Source
---
strain_name                 : varchar(32)
lab_name                    : varchar(64)
organization                : varchar(64)
%}

classdef CollaboratorStrain < dj.Manual
    methods(Static)
        function q = active()
            q = sln_animal.CollaboratorStrain & sln_animal.CollaboratorStrainActive;
        end

        function q = inactive()
            q = sln_animal.CollaboratorStrain - sln_animal.CollaboratorStrainActive;
        end
    end

    methods 
        function activate(self)
            insert(sln_animal.CollaboratorStrainActive,fetch(self));
        end

        function deactivate(self)           
            delQuick(sln_animal.CollaboratorStrainActive & fetch(self));
        end

    end
end

