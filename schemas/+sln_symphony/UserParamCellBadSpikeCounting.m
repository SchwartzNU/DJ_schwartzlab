%{
# UserParamCellBadSpikeCounting
-> sln_symphony.ExperimentCell
---
bad_spike_counting = NULL : enum('T','F') # spike count is not accurate - likely because spikes got small
%}
classdef UserParamCellBadSpikeCounting < dj.Manual
end
