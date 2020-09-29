%{
# brain section

-> sl AnimalEventBrainSectioned
coord : smallint unsigned         # in microns, relative to 0 point of plane
%}

classdef AnimalEventBrainSectionedSlice < dj.Part
  properties(SetAccess=protected)
    master = sl.AnimalEventBrainSectioned
  end
end
