%{
# Animal used for any eye or brain injection
-> sl_test.Animal                                    # which animal
---
%}

classdef AnimalForExperimentalInjection < dj.Part
    properties(SetAccess=protected)
        master = sl_test.Animal
    end
end