%{
# Dataset
-> sl.SymphonyRecordedCell
cell_data                   : varchar(128)                  # name of cellData file
dataset_name                : varchar(128)                  # name of dataset
channel=1                   : int unsigned                  # amplifier channel
---
recording_type=NULL         : enum('Cell attached','Whole cell','Multi','U') #
protocol_name=NULL          : varchar(64)                  # displayName variable name of protocol
protocol_version=NULL       : int unsigned                 # version number of protocol
rstar_mean=NULL             : float                        # background light intensity R*/rod/s
stim_intensity=NULL         : float                        # stimulus intensity R*/rod/s
hold_signal                 : float                        # hold signal mV or pA 
epoch_ids=NULL              : longblob                     # set of epochs in this dataset
%}

classdef Dataset < dj.Manual
    methods(Static)
        function makeTuples(self,key)
            cellData = loadAndSyncCellData(key.cell_data);
            datasetsMap = cellData.savedDataSets;
            key.epoch_ids = datasetsMap(key.dataset_name);
            
            N_epochs = length(key.epoch_ids);
            allModes = cell(1,N_epochs);
            allHold = zeros(1,N_epochs);
            allMeanLevels = zeros(1,N_epochs);
            allProtocols = cell(1,N_epochs);
            allProtocolVersions = zeros(1,N_epochs);
            allStimI = zeros(1,N_epochs);
            
            if key.channel==1
                mode_param = 'recording_mode';
                hold_param = 'amp_hold';
            elseif key.channel==2
                mode_param = 'recording2_mode';
                hold_param = 'amp2_hold';
            else
                disp(['Error: in Dataset initialization, channel ' num2str(key.channel) ' not found']);
                return;
            end
            
            for e=1:N_epochs
                q.cell_id = key.cell_id;
                q.number = key.epoch_ids(e);                
                allModes{e} = fetch1(sl.Epoch & q, mode_param);
                allHold(e) = fetch1(sl.Epoch & q, hold_param);
                allMeanLevels(e) = fetch1(sl.Epoch & q, 'rstar_mean');
                allStimI(e) = fetch1(sl.Epoch & q, 'stim_intensity');
                allProtocols{e} = fetch1(sl.Epoch & q, 'protocol_name');
                allProtocolVersions(e) =fetch1(sl.Epoch & q, 'protocol_version');
            end
            
            unique_modes = unique(allModes);            
            if length(unique_modes) == 1
                key.recording_type = unique_modes{1};
            else
                key.recording_type = 'Multi';
            end
            
            unique_Hold = unique(allHold);            
            if length(unique_Hold) == 1
                key.hold_signal = unique_Hold(1);
            else
                key.hold_signal = NaN;
            end
            
            unique_MeanLevels = unique(allMeanLevels);            
            if length(unique_MeanLevels) == 1
                key.rstar_mean = unique_MeanLevels(1);
            else
                key.rstar_mean = NaN;
            end
            
            unique_stimI = unique(allStimI);            
            if length(unique_stimI) == 1
                key.stim_intensity = unique_stimI(1);
            else
                key.stim_intensity = NaN;
            end
            
            unique_protocols = unique(allProtocols);            
            if length(unique_protocols) == 1
                key.protocol_name = unique_protocols{1};
            else
                key.protocol_name = 'Multi';
            end
            
            unique_protocolV = unique(allProtocolVersions);            
            if length(unique_protocolV) == 1
                key.protocol_version = unique_protocolV(1);
            else
                key.protocol_version = NaN;
            end
            
            self.insert(key)
                        
        end
    end
end

