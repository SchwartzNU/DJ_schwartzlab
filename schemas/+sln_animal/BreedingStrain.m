%{
# A strain from breeding in the lab
strain_name                 : varchar(32)
---
strain_info                 : varchar(64)
%}

classdef BreedingStrain < dj.Manual
    methods(Static)
        function q = active()
            q = sln_animal.BreedingStrain & sln_animal.BreedingStrainActive;
        end

        function q = inactive()
            q = sln_animal.BreedingStrain - sln_animal.BreedingStrainActive;
        end
    end

    methods 
        function activate(self)
            insert(sln_animal.BreedingStrainActive,fetch(self));
        end

        function deactivate(self)           
            delQuick(sln_animal.BreedingStrainActive & fetch(self));
        end

    end
end
