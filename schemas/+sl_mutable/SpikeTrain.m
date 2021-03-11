%{
# SpikeTrain, can have 2 per epoch if there are 2 channels
-> sl.Epoch
channel = 1 : int unsigned  # amplifier channel
---
sp: longblob                # the spike train (vector), NULL if 0 spikes
%}

classdef SpikeTrain < dj.Imported
    properties (Constant)
        keySource = proj(sl.Epoch() & "recording_mode='Cell attached' OR recording2_mode='Cell attached'") * sl_mutable.RecordingChannels - sl_mutable.SpikeTrainMissing;
    end

    methods(Access=protected)
        function makeTuples(self, key)
            % q = self & key;
            % if q.count > 0

            %     previous_ch = fetch1(q, 'channel');
            %     if previous_ch == 1
            %         ch = 2; 
            %         % key.channel = 2;
            %     else
            %         ch = 1; 
            %         % key.channel = 1;
            %     end
            % else
            %     ch = 1;
            % end
            ep = sl.Epoch & key;
            modes = cell(2,1);
            [modes{:}] = ep.fetchn('recording_mode','recording2_mode');

            C = dj.conn;
            if strcmp(C.host, 'localhost') 
                load(['/mnt/fsmresfiles/CellDataMaster/' key.cell_data]);
            else
                cellData = loadAndSyncCellData(key.cell_data);
            end
            epData = cellData.epochs(key.epoch_number);

            for ch = 1:2
            
                % if ch==1
                %     mode = fetch1(ep,'recording_mode');
                % elseif ch==2
                %     mode = fetch1(ep,'recording2_mode');
                % else
                %     error(['SpikeTrain: invalid channel ' num2str(ch)]);
                % end

                if strcmp(modes{ch}, 'Cell attached')
                    sp = epData.get(sprintf('spikes_ch%d', ch));
                    if isnan(sp)
                        new_key = key;
                        new_key.channel = ch;
                        self.del(new_key); %make sure there's no entry
                        sl_mutable.SpikeTrainMissing().declareMissing(new_key);
                    else
                        new_key = key;
                        new_key.sp = sp;
                        new_key.channel = ch;
                        self.insert(new_key);
                    end
                end
            end
        end
    end
end
