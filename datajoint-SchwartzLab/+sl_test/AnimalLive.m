%{
# Live animal
-> sl_test.Animal                                    # which animal
---
%}

classdef AnimalLive < dj.Part
    properties
        cage_mumber
    end
    
    properties(SetAccess=protected)
        master = sl_test.Animal
    end
end
