%{
# Epoch_spikesInPreStimPost
-> sl_results.Epoch     # epoch this entry is for
-> sl.Pipeline = NULL          # analysis pipeline to which this result belongs
---
git_version : varchar(128)     # hash number from "git desccribe --always"
entry_time = CURRENT_TIMESTAMP : timestamp   # when this result was entered into db
%}

classdef EpSpikesInPreStimPost < dj.Part
    properties (SetAccess = protected)
        master = sl_results.Ep;
    end
    
%     properties (Constant)
%        keySource = proj(sl.Epoch & sl_mutable.SpikeTrain);
%     end
    
    methods(Access=protected)
        function makeTuples(self, key)
%             curDir = pwd;
%             cd(getenv('DJ_ROOT'));
%             [err, hash] = system('git describe --always');
%             cd(curDir);
%             if ~err
%                 key.git_version = deblank(hash);
%             else
%                 disp('git error');
%             end
            self.insert(key)
        end
    end
end