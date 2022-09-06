%{ 
# The name of a strain of animals, used to reflect intended genotype

strain_name                 : varchar(64) 
->sln_animal.Background # this should not be a primary key
---
-> sln_animal.Species

%}
classdef Strain < dj.Manual
    methods(Static)
        function q = active()
            q = sln_animal.Strain & sln_animal.StrainActive;
        end

        function q = inactive()
            q = sln_animal.Strain - sln_animal.StrainActive;
        end
    end

    methods
        function activate(self)
            insert(sln_animal.StrainActive,fetch(self));
        end

        function deactivate(self)
            delQuick(sln_animal.StrainActive & fetch(self));
        end
    end
end