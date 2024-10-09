%{
# Uncaging Runner
-> sln_symphony.Dataset
---
analysis_name                   : varchar(128) # name of analysis
analysis_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
%}
classdef UncagingRunner < dj.Computed
    properties
        keySource = sln_symphony.Dataset & ...
            (sln_symphony.Dataset * ...
            sln_symphony.DatasetEpoch * ...
            aka.Epoch * ...
            sln_symphony.ExperimentEpochBlock * ...
            sln_symphony.ExperimentElectrode & ...
            'protocol_name="uncaging"' & ...
            'amp_mode="Whole cell"' & ...
            'recording_mode="Voltage clamp"')
    end

    methods(Access=protected)
        function makeTuples(self, key)
            key.analysis_name = 'Uncaging';
            q = sln_results.DatasetUncaging & key & 'LIMIT 1 PER source_id ORDER BY entry_time DESC';
            if q.exists
                key.git_tag = fetch1(q,'git_tag');
                self.insert(key);
            else
                try
                    R = Uncaging(key);
                    sln_results.insert(R,'Dataset','false');
                    q = sln_results.DatasetUncaging & key & 'LIMIT 1 PER source_id ORDER BY entry_time DESC';
                    key.git_tag = fetch1(q,'git_tag');
                    self.insert(key);
                catch ME
                    disp(ME.message);
                    rethrow(ME);
                end
            end
        end
    end

    methods 
        function err = errors(self)
            err = self.keySource - sln_results.UncagingRunner;
        end
    end
end