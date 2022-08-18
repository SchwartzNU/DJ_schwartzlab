%{
# Presence of a specific allele, where number of entries reflects zygosity
-> sln_animal.Animal
-> sln_animal.GeneLocus
allele_id               : tinyint unsigned            # up to ploidy number
---
-> [nullable] sln_animal.GenotypeResult #null if inferred or from jax, etc.
-> sln_animal.Allele
inheritance = NULL      : enum('maternal','paternal') # source, if known
%}
classdef Genotype < dj.Manual
end