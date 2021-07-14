%{
# SpikeTrain, can have 2 per epoch if there are 2 channels
-> sl.Epoch
channel = 1 : int unsigned  # amplifier channel
---
count : int unsigned        # number of spikes in the epoch
sp: longblob                # the spike train (vector), NULL if 0 spikes
%}

classdef SpikeTrain < dj.Imported
    properties (Constant)
        % keySource = proj(...
        %         (sl.Epoch & "recording_mode='Cell attached' OR recording2_mode='Cell attached'")...
        %         * sl_mutable.RecordingChannels...
        %      ) - sl_mutable.SpikeTrainMissing...
        %      & "(recording_mode='Cell attached' AND channel=1) OR (recording2_mode='Cell attached' AND channel=2)";

        keySource = proj(...
             (sl.Epoch & "recording_mode='Cell attached' OR recording2_mode='Cell attached' OR (recording_mode='Whole cell' AND (cell_id LIKE '040221Ac%' OR cell_id LIKE '040821Ac%' OR cell_id LIKE '041521Ac%' OR cell_id LIKE '042221Ac%' OR cell_id LIKE '051121Ac%' OR cell_id LIKE '051821Ac%'))")... #796 whole cell epochs, for testing
             * sl_mutable.RecordingChannels...
          ) - sl_mutable.SpikeTrainMissing...
          & "(recording_mode='Cell attached' AND channel=1) OR (recording2_mode='Cell attached' AND channel=2) OR (recording_mode='Whole cell' AND channel=1 AND (cell_id LIKE '040221Ac%' OR cell_id LIKE '040821Ac%' OR cell_id LIKE '041521Ac%' OR cell_id LIKE '042221Ac%' OR cell_id LIKE '051121Ac%' OR cell_id LIKE '051821Ac%'))";
    end

    methods(Access=protected)
        function makeTuples(self, key)
            
            C = dj.conn;
            if strcmp(C.host, '127.0.0.1:3306') 
                load(['/mnt/fsmresfiles/CellDataMaster/' key.cell_data]);
            else
                cellData = loadAndSyncCellData(key.cell_data);
                %TODO: should get local cell data if possible but seems
                %busted right now
                %load(sprintf('%s/%s', getenv('CELL_DATA_FOLDER'), key.cell_data));
            end
            epData = cellData.epochs(key.epoch_number);
            sp = epData.get(sprintf('spikes_ch%d', key.channel));
            if isnan(sp)
                sl_mutable.SpikeTrainMissing().declareMissing(key);
            else
                key.sp = sp;
                key.count = numel(sp);
                self.insert(key);
            end
        end
    end
end
