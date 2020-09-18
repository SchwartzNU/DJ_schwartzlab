%{
# Dataset
-> sl.RecordedNeuron
cell_data                   : varchar(128)                  # name of cellData file
dataset_name                : varchar(128)                  # name of dataset
channel=1                   : int unsigned                  # amplifier channel
---
recording_type              : enum('Cell attached','Whole cell','Multi','U') #
epoch_ids                   : longblob                      # set of epochs in this dataset
%}

classdef Dataset < dj.Manual
    methods(Access=protected)
        function makeTuples(self,key)
            %add dataset
            curName = key.cell_data;
            [~, ch] = strtok(curName, '-');
            key.channel = 1;
            if ~isempty(ch)
                key.channel = str2double(ch(4));
            end
                        
            datasetsMap = key.cell_data.savedDataSets;
            key.epoch_ids = datasetsMap(key.dataset_name);
            key.dataset_name = strrep(key.dataset_name, '.', '_dot_'); %make sure dataset_name is legal 
            
            N_epochs = length(key.epoch_ids);
            allModes = cell(1,N_epochs); 
            if key.channel==1
                mode_param = 'recording_mode';
            elseif key.channel==2
                mode_param = 'recording2_mode';
            else
                disp(['Error: in Dataset initialization, channel ' num2str(key.channel) ' not found']);
                return;
            end
            
            for e=1:N_epochs
               q.cell_id = key.cell_id;
               q.number = key.epoch_ids(e);
               allModes{e} = fetch1(sl.Epoch & q, mode_param);
            end
            
            unique_modes = unique(allModes);
            
            if length(unique_modes) == 1
                key.recording_type = unique_modes{1};
            else
                key.recording_type = 'Multi';
            end
            
            %now the specific calls for each kind of dataset
            if startsWith(dataset_name, 'SpotsMultiSize') %only for SMS datasets
                sl.DatasetSMS.makeTuples(key);
            end            
            
            self.insert(key);      
            
        end
    end
end

