%{
# User-labelled spike trains 
->sln_symphony.SymphonyEpochChannel
---
spike_indices = NULL: blob@raw
spike_count : int unsigned
%}
classdef SpikeTrain < dj.Manual
  methods
    function insert(self, key)

      %assert that channels must be electrodes
      assert(count(...
      sln_symphony.SymphonyElectrode...
      * sln_symphony.SymphonyEpochChannel...
       & rmfield(key, {'spike_indices','spike_count'}))...
       == numel(key),...
       'Channel must be an electrode!');
      
      insert@dj.Manual(self, key);
    end
  end
end

%TODO: in the future, maybe we can automatically compute these?