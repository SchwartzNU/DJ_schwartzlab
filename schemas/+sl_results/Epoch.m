%{
# Epoch result stores computed information for an epoch
-> sl.Epoch     # epoch this entry is for
---
%}

classdef Epoch < dj.Computed

    methods(Access=protected)
        function makeTuples(self, key)
            self.insert(key)
            %makeTuples(test.SegmentationRoi, key)
        end
    end
end