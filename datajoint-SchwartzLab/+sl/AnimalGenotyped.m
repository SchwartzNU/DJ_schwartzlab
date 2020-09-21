%{
# Genotyped animal
-> sl.Animal                                    # which animal
---
genotype_status: enum('Het', 'Homo', 'Non-carrier', 'Carrier', 'Unknown')  # positive means positive for multiple genes if double or triple trans., het or homo only if we know 
%}

classdef AnimalGenotyped < dj.Part
    properties(SetAccess=protected)
        master = sl.Animal
    end
end
