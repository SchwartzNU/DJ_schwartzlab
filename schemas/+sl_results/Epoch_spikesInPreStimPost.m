%{
# Epoch_spikesInPreStimPost
-> sl_results.Epoch     # epoch this entry is for
epoch_func_name: varchar(64) #epoch function used to generate result
---
-> sl.Pipeline = NULL          # analysis pipeline to which this result belongs
entry_time = CURRENT_TIMESTAMP : timestamp   # when this result was entered into db
%}

classdef Epoch_spikesInPreStimPost < dj.Part
    properties (SetAccess = protected)
        master = sl_results.Epoch
    end
    
    properties (Constant)
       keySource = proj(sl.Epoch & sl_mutable.SpikeTrain)
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            self.insert(key)
            %makeTuples(test.SegmentationRoi, key)
        end
    end
end