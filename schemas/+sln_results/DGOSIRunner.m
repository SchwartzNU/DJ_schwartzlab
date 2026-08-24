%{
#DGOSIRunner
-> sln_symphony.Dataset
---
analysis_name : varchar(128)
analysis_entry_time = CURRENT_TIMESTAMP : timestamp
git_tag : varchar(128)
%}
classdef DGOSIRunner < dj.Computed
    properties
        keySource = sln_symphony.Dataset & (...
            sln_symphony.Dataset * ...
            sln_symphony.DatasetEpoch * ...
            aka.Epoch * ...
            sln_symphony.ExperimentEpochBlock * ...
            sln_symphony.ExperimentElectrode & ...
            'protocol_name="drifting_gratings"' & ...
            'amp_mode="Whole cell" or amp_mode LIKE "Perforated%"'  & ...
            'recording_mode="Voltage clamp"')
    end
    methods(Access=protected)
        function makeTuples(self, key)
            key.analysis_name = 'DG_OSI_by_cell',
            R = DG_OSI_by_cell(key);
            sln_results.insert(R, 'Dataset','false');
            q = sln_results.DatasetDGOSIbycell & key & 'LIMIT 1 PER source_id ORDER BY entry_time DESC';
            if q.exists
                key.git_tag = fetch1(q,'git_tag');
                self.insert(key);
            else
                try
                    R = DG_OSI_by_cell(key);
                    sln_results.insert(R,'Dataset','false');
                    q = sln_results.DatasetDGOSIbycell & key & 'LIMIT 1 PER source_id ORDER BY entry_time DESC';
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
            err = self.keySource - sln_results.DG_OSI_by_cell;
        end
    end
end
