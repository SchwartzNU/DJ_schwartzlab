%{
# Animal used for any eye or brain injection
-> sl.Animal                                    # which animal
---
%}

classdef AnimalForExperimentalInjection < dj.Part
    properties(SetAccess=protected)
        master = sl.Animal
    end
end
