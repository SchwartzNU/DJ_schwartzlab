%{
 # Genotype of the animal
 genotype_name : varchar(64)          # the name of this genotype
 ---
 source = NULL : varchar(32)                 # vendor or lab
 catalog_number = NULL : varchar(32)         # catalog number as text fieldd
 description = NULL : varchar(128)    # explanation of this genotype (include information about whether it is inducible and by what means)
%}
classdef Genotype < dj.Lookup
    
end