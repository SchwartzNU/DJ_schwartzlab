%{
# MBCARunner
-> sln_symphony.Dataset
---
analysis_name                   : varchar(128) # name of analysis
analysis_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
%}
classdef MBCARunner < dj.Computed
    properties
        keySource = sln_symphony.Dataset & ...
            (sln_symphony.Dataset * ...
            sln_symphony.DatasetEpoch * ...
            aka.Epoch * ...
            sln_symphony.ExperimentEpochBlock * ...
            sln_symphony.ExperimentElectrode & ...
            'protocol_name="moving_bar"' & ...
            'amp_mode="Cell attached"')
    end

    methods(Access=protected)
        function makeTuples(self, key)
            key.analysis_name = 'MovingBar_CA';
            q = sln_results.DatasetMovingBarCA & key & 'LIMIT 1 PER source_id ORDER BY entry_time DESC';
            if q.exists
                key.git_tag = fetch1(q,'git_tag');
                self.insert(key);
            else
                try
                    R = MovingBar_CA(key);
                    sln_results.insert(R,'Dataset','false');
                    q = sln_results.DatasetMovingBarCA & key & 'LIMIT 1 PER source_id ORDER BY entry_time DESC';
                    key.git_tag = fetch1(q,'git_tag');
                    self.insert(key);
                catch ME
                    disp(ME.message);
                end
            end
        end
    end

    methods 
        function err = errors(self)
            err = self.keySource - sln_results.MBCARunner;
        end
    end
end