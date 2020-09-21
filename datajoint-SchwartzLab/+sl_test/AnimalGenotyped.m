%{
# Genotyped animal
-> sl_test.Animal                                    # which animal
---
genotype_status: enum('Het', 'Homo', 'Non-carrier', 'Carrier', 'Unknown')  # positive means positive for multiple genes if double or triple trans., het or homo only if we know 
%}

classdef AnimalGenotyped < dj.Part
    properties(SetAccess=protected)
        master = sl_test.Animal
    end
end
