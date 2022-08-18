%{
# A table with identifying information for a strain, if not from breeeding
-> sln_animal.Strain
---
-> sln_animal.Source
strain_id = NULL: varchar(64) # ex., a catalog number
%}
classdef StrainSource < dj.Part
properties (SetAccess = protected)
    master = sln_animal.Strain
end
end