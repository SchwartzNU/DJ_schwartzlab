%{
# SpikeTrainMissing, can have 2 per epoch if there are 2 channels
-> sl.Epoch
channel = 1 : int unsigned  # amplifier channel
---
%}

classdef SpikeTrainMissing < dj.Imported
  methods(Access=protected)
    function makeTuples(self, key)
      self.insert(key);
    end
  end

  methods
    function declareMissing(self, key)
      self.insert(key);
    end
  end
end