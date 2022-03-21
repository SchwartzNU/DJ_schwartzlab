%{
# Alleles for an animal line from a vendor
-> sln_animal.Line
-> sln_animal.Allele
---
%}

classdef LineAllele < dj.Part
    properties
        master = sln_animal.Line;
    end
end

