%{
# A location on the genome for alleles

locus_name              : varchar(16)
---
description             : varchar(128)

chromosome = NULL       : tinyint unsigned
position = NULL         : decimal(2,2) # position along chromosome in cM

%}
classdef GeneLocus < dj.Manual
end