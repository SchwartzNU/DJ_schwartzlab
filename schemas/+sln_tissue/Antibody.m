%{
#An antibody
-> sln_tissue.StainReagent
---
antibody_target : varchar(128) # antibody target
clonality : enum('mono', 'poly', 'unknown')
-> sln_tissue.Host
%}

classdef Antibody < dj.Lookup

end