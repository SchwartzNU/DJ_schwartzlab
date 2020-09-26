%{
# brain section

-> sl_test AnimalEventBrainSectioned
coord : smallint unsigned         # in microns, relative to 0 point of plane
%}

classdef AnimalEventBrainSectionedSlice < dj.Part
  properties(SetAccess=protected)
    master = sl_test.AnimalEventBrainSectioned
  end
end
