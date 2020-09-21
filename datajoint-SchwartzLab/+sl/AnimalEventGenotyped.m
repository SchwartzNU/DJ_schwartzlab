%{
# animal genotyped
-> sl.AnimalEvent                                                # date of genotype
---
result: enum('Het', 'Homo', 'Non-carrier', 'Carrier', 'Unknown')  # positive means positive for multiple genes if double or triple trans., het or homo only if we know 
notes: varchar(128)                                               # comment if the result was ambiguous or any additional notes
(genotyped_by) -> sl.User(name)                              # who did the genotye
%}

classdef AnimalEventGenotyped < dj.Part
     properties(SetAccess=protected)
        master = sl.AnimalEvent
    end
end

