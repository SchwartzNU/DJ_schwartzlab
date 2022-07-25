%{
# injected substance (virus, beads, dye, etc)

substance_id : smallint unsigned auto_increment 
---
source : varchar(32)                 # vendor or lab
substance_name : varchar(32)         # name of substance (e.g. AAV2-Cre)
catalog_number: varchar(32)          # catalog number (as text)
storage_location: varchar(128)       # storage location in the lab
description: varchar(256)            # anything about this substance
%}

classdef InjectionSubstance < dj.Lookup
    methods(Static)
        function q = active()
            q = sln_animal.InjectionSubstance & sln_animal.InjectionSubstanceActive;
        end

        function q = inactive()
            q = sln_animal.InjectionSubstance - sln_animal.InjectionSubstanceActive;
        end
    end

    methods
        function activate(self)
            insert(sln_animal.InjectionSubstanceActive,fetch(self));
        end

        function deactivate(self)
            delQuick(sln_animal.InjectionSubstanceActive & fetch(self));
        end
    end
end
