%{
# A strain from an animal vendor
-> sln_animal.Source
---
vendor_name                 : varchar(64)
%}

classdef Vendor < dj.Manual
    methods(Static)
        function q = active()
            q = sln_animal.Vendor & sln_animal.VendorActive;
        end

        function q = inactive()
            q = sln_animal.Vendor - sln_animal.VendorActive;
        end
    end

    methods 
        function activate(self)
            insert(sln_animal.VendorActive,fetch(self));
        end

        function deactivate(self)           
            delQuick(sln_animal.VendorActive & fetch(self));
        end
    end
end
