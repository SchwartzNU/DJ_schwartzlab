%{
# SpikeDetector for CurrentClamp Epochs
-> sln_symphony.ExperimentEpoch
-> sln_symphony.ExperimentElectrode
---
detection_mode : varchar(64) #way the detection was done
analysis_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
%}
classdef SpikeDetectCC < dj.Computed
    properties
        keySource = aka.Epoch * ...
            sln_symphony.ExperimentElectrode & ...
            'amp_mode="Whole cell"' & ...
            'recording_mode="Voltage clamp"'
        MIN_PEAK_PROMINENCE = 6; %mV
        MIN_PEAK_HEIGHT = -15 %mV
        MIN_PEAK_DISTANCE = .001; %s
    end

    methods(Access=protected)
        function makeTuples(self, key)
            q = sln_symphony.SpikeTrain & key;
            if q.exists
                key.detection_mode = 'SpikeDetector GUI';
                self.insert(key);
            else
                try
                    trace = fetch1(sln_symphony.ExperimentEpochChannel & key, 'raw_data');
                    sample_rate = fetch1(sln_symphony.ExperimentChannel & key, 'sample_rate');

                    [~, sp] = findpeaks(trace, sample_rate,...
                    "MinPeakProminence", self.MIN_PEAK_PROMINENCE, ...
                    "MinPeakHeight", self.MIN_PEAK_HEIGHT, ...
                    "MinPeakDistance", self.MIN_PEAK_DISTANCE);

                    sp_train_key = key;

                    sp_train_key.spike_count = length(sp);
                    sp_train_key.spike_indices = sp;
                    insert(sln_symphony.SpikeTrain, sp_train_key);
                  
                    key.detection_mode = 'findpeaks';
                    self.insert(key);
                catch ME
                    disp(ME.message);
                end
            end
        end
    end

    methods 
        function err = errors(self)
            err = self.keySource - sln_symphony.SpikeTrain;
        end
    end
end