%{
# UserParamCellCcQuality
-> sln_symphony.ExperimentCell
---
cc_quality = NULL : enum('low', 'mid', 'high') # quality of current-clamp data in best dataset (typically MP)
%}
classdef UserParamCellCcQuality < dj.Manual
end
