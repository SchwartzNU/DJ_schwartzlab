%{
# UserParamCellDrugTime
-> sln_symphony.ExperimentCell
---
drug_time = NULL : varchar(64) # time the drug was added. Make sure you specify as HH:MM with military time
%}
classdef UserParamCellDrugTime < dj.Manual
end
