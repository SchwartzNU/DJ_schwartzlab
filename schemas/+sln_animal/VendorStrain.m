%{
# A strain from an animal vendor
-> sln_animal.Source
---
strain_name                 : varchar(16)
vendor_name                 : varchar(64)
catalog_number              : varchar(32)
%}

classdef VendorStrain < dj.Manual
end
