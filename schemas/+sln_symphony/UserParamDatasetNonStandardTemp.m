%{
# UserParamDatasetNonStandardTemp
-> sln_symphony.Dataset
---
non_standard_temp = NULL : enum('T','F') # if temperature is not 32
%}
classdef UserParamDatasetNonStandardTemp < dj.Manual
end
