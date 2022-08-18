%{
# A strain from an animal vendor
-> sln_animal.Source
---
vendor_name                 : varchar(64)
%}

classdef Vendor < dj.Manual
    methods(Static)
        function q = active()
            q = sln_animal.VendorStrain & sln_animal.VendorStrainActive;
        end

        function q = inactive()
            q = sln_animal.VendorStrain - sln_animal.VendorStrainActive;
        end
    end

    methods 
        function activate(self)
            insert(sln_animal.VendorStrainActive,fetch(self));
        end

        function deactivate(self)           
            delQuick(sln_animal.VendorStrainActive & fetch(self));
        end
    end
end
