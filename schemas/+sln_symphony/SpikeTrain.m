%{
# User-labelled spike trains 
->sln_symphony.ExperimentEpochChannel
---
spike_indices = NULL: blob
spike_count : int unsigned
%}
classdef SpikeTrain < dj.Manual
  methods
    function insert(self, key)

      %assert that channels must be electrodes
      assert(count(...
      sln_symphony.ExperimentElectrode...
      * sln_symphony.ExperimentEpochChannel...
       & rmfield(key, {'spike_indices','spike_count'}))...
       == numel(key),...
       'Channel must be an electrode!');

      % reduce the space requirement
      last = max(key.spike_indices);
      if last < intmax('uint8')
        key.spike_indices = uint8(key.spike_indices);
      elseif last < intmax('uint16')
        key.spike_indices = uint16(key.spike_indices);
      else %we will never ever exceed uint32
        key.spike_indices = uint32(key.spike_indices);
      end
      insert@dj.Manual(self, key);
    end
  end
end

%TODO: in the future, maybe we can automatically compute these?