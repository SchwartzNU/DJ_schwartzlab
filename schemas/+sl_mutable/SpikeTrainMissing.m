%{
# SpikeTrainMissing, can have 2 per epoch if there are 2 channels
-> sl.Epoch
channel = 1 : int unsigned  # amplifier channel
---
sp: longblob                # the spike train (vector), NULL if 0 spikes
%}

classdef SpikeTrain < dj.Imported
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