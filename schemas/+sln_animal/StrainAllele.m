%{
# A map of which alleles to test for a strain
-> sln_animal.Strain
-> sln_animal.Allele

%}
classdef StrainAllele  < dj.Part
properties (SetAccess = protected)
    master = sln_animal.Strain
end
end