%{
# Epoch result stores computed information for an epoch
-> sl.Epoch     # epoch this entry is for
---
%}

classdef Ep < dj.Computed

    methods(Access=protected)
        function makeTuples(self, key)
            self.insert(key)
            %makeTuples(test.SegmentationRoi, key) # for each one starting with Ep_s
        end
    end
end