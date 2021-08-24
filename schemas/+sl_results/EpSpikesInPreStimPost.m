%{
# EpSpikesInPreStimPost
-> sl.Epoch               # epoch this entry is for
func_name = "SpikesInPreStimPost" : varchar(128) # function name
-> sl.Pipeline            # analysis pipeline to which this result belongs
---
git_version : varchar(128)     # hash number from "git describe --always"
entry_time = CURRENT_TIMESTAMP : timestamp   # when this result was entered into db
%}

classdef EpSpikesInPreStimPost < dj.Computed
    
    properties (Constant)
        keySource = sl.Epoch & sl_mutable.SpikeTrain;
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            key.pipeline_name = "scratch";
            curDir = pwd;
            cd(getenv('DJ_ROOT'));
            [err, hash] = system('git describe --always');
            cd(curDir);
            if ~err
                key.git_version = deblank(hash);
            else
                disp('git error');
            end            
            self.insert(key)
        end
    end
end


%
