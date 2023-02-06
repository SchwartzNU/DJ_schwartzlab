%{
# UserParamDatasetBadParamSet
-> sln_symphony.Dataset
---
bad_param_set = NULL : enum('T','F') # parameter set that does not match others. Can exclude from analysis.
%}
classdef UserParamDatasetBadParamSet < dj.Manual
end
