%{
# A version of a gene

-> sln_animal.GeneLocus
allele_name                     : varchar(16)
---
description                     : varchar(128)
is_wildtype                     : enum('F','T')
-> sln_animal.Vendor                     # the source for this allele
%}
classdef Allele < dj.Manual
end
%TODO: should the vendor be here? in the pk?