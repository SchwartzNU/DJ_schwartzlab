%{
# A source for genotyping results
->sln_animal.Source
---
source_name     : varchar(16)
description     : varchar(128)

%}
classdef GenotypeSource < dj.Manual
      methods(Static)
        function q = active()
            q = sln_animal.GenotypeSource & sln_animal.GenotypeSourceActive;
        end

        function q = inactive()
            q = sln_animal.GenotypeSource - sln_animal.GenotypeSourceActive;
        end
    end

    methods 
        function activate(self)
            insert(sln_animal.GenotypeSourceActive,fetch(self));
        end

        function deactivate(self)           
            delQuick(sln_animal.GenotypeSourceActive & fetch(self));
        end
    end
    
end