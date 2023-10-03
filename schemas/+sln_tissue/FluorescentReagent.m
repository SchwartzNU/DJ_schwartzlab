%{
#A fluorescent reagent
-> sln_tissue.StainReagent
---
target_molecule = NULL : varchar(32) # target for a something like alexa-conjugated streptavidin or alexa-conjugated antibody
(target_species) -> [nullable] sln_tissue.Host #target species if fluorescent secondary
-> [nullable] sln_tissue.Host #host species if there is one
-> sln_tissue.ColorChannel
%}

classdef FluorescentReagent < dj.Lookup

end