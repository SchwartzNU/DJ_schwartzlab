%{
# A version of a gene

allele_name                     : varchar(16)
---
description                     : varchar(128)
is_wildtype                     : enum('F','T')
%}
classdef Allele < dj.Manual
end
%TODO: should the vendor be here? in the pk?
%-> sln_animal.Vendor                     # the source for this allele
