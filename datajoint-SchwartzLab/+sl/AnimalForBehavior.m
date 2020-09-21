%{
# Animal used for any behavioral experiment
-> sl.Animal                                    # which animal
---
%}

classdef AnimalForBehavior < dj.Part
    properties(SetAccess=protected)
        master = sl.Animal
    end
end
