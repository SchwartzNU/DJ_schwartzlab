%{
# SMSCCRunner
-> sln_symphony.Dataset
---
analysis_name                   : varchar(128) # name of analysis
analysis_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
%}
classdef SMSCCRunner < dj.Computed
    properties
        keySource = sln_symphony.Dataset & ...
            (sln_symphony.Dataset * ...
            sln_symphony.DatasetEpoch * ...
            aka.Epoch * ...
            sln_symphony.ExperimentEpochBlock * ...
            sln_symphony.ExperimentElectrode & ...
            'protocol_name="spots_multi_size"' & ...
            'amp_mode="Whole cell"' & ...
            'recording_mode="Voltage clamp"')
    end

    methods(Access=protected)
        function makeTuples(self, key)
            key.analysis_name = 'SMS_CC';
            R = SMS_CC(key);
            
            key
            %keyboard;
        end

    end

end