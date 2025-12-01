%{
# Brain version of sln_symphony.SpikeTrain
->sln_symphony.ExperimentEpochChannel
->sln_symphony.ExperimentBrainElectrode
---
spike_indices = NULL: blob
spike_count : int unsigned
%}
classdef SpikeTrainBrain < dj.Manual
  methods
    function insert(self, key, replace)
        if nargin<3
            replace = false;
        else
            replace = true;
        end

      % reduce the space requirement
      key = arrayfun(@convertToUint, key);      
      if replace
          insert@dj.Manual(self, key, 'REPLACE');
      else
          insert@dj.Manual(self, key);
      end
    end
    end

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

%TODO: in the future, maybe we can automatically compute these?