%{
# UserParamDatasetAmesGlucose
-> sln_symphony.Dataset
---
ames_glucose = NULL : enum('control', 'high', 'wash') # Glucose level in the Ames. Control is 100 mg/dL. High is 300 mg/dL.
%}
classdef UserParamDatasetAmesGlucose < dj.Manual
end
