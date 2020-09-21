%{
# Animal used for any behavioral experiment
-> sl_test.Animal                                    # which animal
---
%}

classdef AnimalForBehavior < dj.Part
    properties(SetAccess=protected)
        master = sl_test.Animal
    end
end