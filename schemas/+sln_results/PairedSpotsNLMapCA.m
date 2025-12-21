%{
# PairedSpotsNLMapCA
-> sln_symphony.Dataset
---
analysis_name                   : varchar(128) # name of analysis
analysis_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
%}
classdef PairedSpotsNLMapCA < dj.Computed
    properties
        keySource = sln_results.DatasetPairedSpotsCA;
    end
     methods(Access=protected)
        function makeTuples(self, key)
            disp('populing NL map')
            key

        end
     end

end