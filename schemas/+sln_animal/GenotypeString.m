function q = GenotypeString()

 q =  proj(...
    aggr(sln_animal.Animal, ... %final result will have 1 entry per animal
        proj(...
            aggr((sln_animal.Animal * sln_animal.GeneLocus ) ...%intermediate result has 1 entry per animal/locus
                & proj(sln_animal.Animal * sln_animal.StrainAllele * sln_animal.AlleleLocusMap * sln_animal.GeneLocus),... %... but only if we expect to test that locus for this strain
                sln_animal.Genotype,... % start with 1 entry per animal/allele
                'group_concat(allele_name separator "/")->temp1'... %merge alleles at same locus with a "/"
            ),'IF(temp1 is null, concat(locus_name, "(?/?)"),IF(temp1 LIKE "%/%",concat(locus_name, "(",temp1,")"),concat(locus_name, "(", temp1, "/?)")))->temp2'... %add the locus and a trailing "/?" if only one known allele
        ),'group_concat(temp2 separator ",")->genotype_string',... %join the loci with a comma
        'strain_name'),...
    'IF(genotype_string is null, IF(strain_name="WT", "WT", "?"), genotype_string) -> genotype_string'); %for WT animals, fill in with "WT"; for ungenotyped animals, fill in with "?"

%% example output:
% ANIMAL_ID                                    genotype_string                                
% _________    _______________________________________________________________________________
%
%   1            {'WT'}     
%       ...

%   1710       {'?'                                                                          }
%   1711       {'Igs7(WT/WT),Rosa26(GCaMP6f/?),unknown(WT/WT)'                               }
%   1712       {'Igs7(TITL iGluSnFR/WT),unknown(Grm6-Cre/?)'                                 }

%       ...
end