%{
# DrugCondition
drug_condition_name : varchar(64)
---
notes = NULL : varchar(256) # description of condition 
%}
classdef DrugCondition < dj.Lookup
    methods(Static)

    end
end