%{
# User-labelled spike trains 
->sln_symphony.ExperimentEpochChannel
->sln_symphony.ExperimentElectrode
---
spike_indices = NULL: blob
spike_count : int unsigned
%}
classdef SpikeTrain < dj.Manual
  methods
    function insert(self, key)

      % reduce the space requirement
      key = arrayfun(@convertToUint, key);
      insert@dj.Manual(self, key);
    end

    function key = convertToUint(key)
      last = max(key.spike_indices);
      if last < intmax('uint8')
        key.spike_indices = uint8(key.spike_indices);
      elseif last < intmax('uint16')
        key.spike_indices = uint16(key.spike_indices);
      else %we will never ever exceed uint32
        key.spike_indices = uint32(key.spike_indices);
      end
    end
  end

end

%TODO: in the future, maybe we can automatically compute these?