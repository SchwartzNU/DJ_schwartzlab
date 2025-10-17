%{
# UserParamDatasetExtraSms
-> sln_symphony.Dataset
---
extra_sms = NULL : enum('T','F') # non-primary SMS dataset
%}
classdef UserParamDatasetExtraSms < dj.Manual
end
