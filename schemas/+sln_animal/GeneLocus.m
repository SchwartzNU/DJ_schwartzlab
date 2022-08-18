%{
# A location on the genome for alleles

locus_name              : varchar(32)
---
description             : varchar(128)

chromosome = NULL       : tinyint unsigned
position = NULL         : float # position along chromosome in cM

%}
classdef GeneLocus < dj.Manual
end