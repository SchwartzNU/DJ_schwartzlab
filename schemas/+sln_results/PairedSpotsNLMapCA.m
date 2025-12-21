%{
# PairedSpotsNLMapCA
-> sln_symphony.Dataset
---
single_spots_resp_map : longblob
paired_spots_nli_map : longblob
paired_spots_distance : longblob
paired_spots_nli : longblob
analysis_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
%}
classdef PairedSpotsNLMapCA < dj.Computed
    properties
        keySource = sln_results.DatasetPairedSpotsCA;
    end
     methods(Access=protected)
        function makeTuples(self, key)
            disp('populing NL map')
            R = fetch(sln_results.DatasetPairedSpotsCA & key, '*');
            Ncontrasts = length(R.contrast);
            
            
            keyboard;

        end
     end

end