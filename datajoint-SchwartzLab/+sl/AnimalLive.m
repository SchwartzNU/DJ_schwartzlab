%{
# Live animal
-> sl.Animal                                    # which animal
---
cage_number : smallint unsigned                      # cage number in which animal is currently housed
%}

classdef AnimalLive < dj.Part
    properties(SetAccess=protected)
        master = sl.Animal
    end
end
