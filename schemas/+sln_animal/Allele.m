%{
# A version of a gene

allele_name                     : varchar(16)
---
description                     : varchar(128)
is_wildtype                     : enum('F','T')
%}
classdef Allele < dj.Manual
    methods(Static)
        function q = active()
            q = sln_animal.Allele & sln_animal.AlleleActive;
        end

        function q = inactive()
            q = sln_animal.Allele - sln_animal.AlleleActive;
        end
    end

    methods
        function activate(self)
            insert(sln_animal.AlleleActive,fetch(self));
        end

        function deactivate(self)
            delQuick(sln_animal.AlleleActive & fetch(self));
        end
    end
end

