%{
# UserParamDatasetQualitySuspect
-> sln_symphony.Dataset
---
quality_suspect = NULL : enum('T','F') # a tag to be added to datasets of suspect quality. Can be of any type. Can be later removed if they turn out to be ok.
%}
classdef UserParamDatasetQualitySuspect < dj.Manual
end
