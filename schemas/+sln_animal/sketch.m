% + ROSA(wt) + GCaMP

%Genotype:
% key.animal_id...
% key.locus_name = ROSA
% key.allele_id = 1
% key.allele_name = 'ROSA_WT' %iswildtype = T

% key.animal_id
% key.locus_name = ROSA
% key.allele_id = 2
% key.allele_name = 'GCaMP' %iswildtype = F


% is_het_or_carrier
% count(sln_animal.Genotype & animal_id... & allele_name = 'GCaMP') == 1
% ... count(for this animal)
% 


% GenotypeResult

% 
% key.animal_id...
% key.locus_name = ROSA
% key.allele_id = 1
%key.user...
% key.time