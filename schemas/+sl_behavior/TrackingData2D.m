%{
# Behavior session tracking data 2D (top camera)

-> sln_animal.SocialBehaviorSession
---
time_axis : longblob            # vector with units of seconds 
n_frames : int unsigned         # number of frames
dlc_raw : longblob              # struct with dlc positions and confidence data
%}

classdef TrackingData2D < dj.Imported
     methods(Access=protected)
        function makeTuples(self, key)  
            C = dj.conn;
            if strcmp(C.host, '127.0.0.1:3306') 
               rootFolder = '/mnt/fsmresfiles/behavior';
            elseif exist(getenv('SERVER_ROOT'), 'dir')
               rootFolder = [getenv('SERVER_ROOT') filesep 'BehaviorMaster'];
            else
               disp('Aborting BehaviorSessionTrackingData import: Behavior folder not found');
            end
           
            thisSession = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('event_id=%d',key.event_id);
            animal_id = fetch1(thisSession,'animal_id');
            animal_folder = sprintf('%s%s%d',rootFolder, filesep, animal_id);
            temp = dir([rootFolder filesep num2str(animal_id)]);
            session_folders = {temp.name};  
            ind = find(startsWith(session_folders,[num2str(key.event_id) '_']));

            if length(ind)==1
                folder_name = [animal_folder filesep session_folders{ind}];
            else
                fprintf('Folder for session %d not found.\n', key.event_id);
                return;
            end
                        
            frameRate = 15; %Hz, TODO, read this in from calibration;
            %todo: find the right camera correctly!
            
            camera_serial_number = '17391304';
            if exist([folder_name filesep 'DLC_new'], 'dir')
                dlc_files = dir([folder_name filesep 'DLC_new']);
                dlc_filenames = {dlc_files.name};

                ind = find(startsWith(dlc_filenames, ['camera_' camera_serial_number]) ...
                    & endsWith(dlc_filenames, '.csv'));
            else
                disp('DLC_new folder not found');
                return;
            end
            
            if isempty(ind)
                disp('CSV file not found');
                return;
            end

            csv_fname = dlc_filenames{ind};    
            fname = [folder_name filesep 'DLC_new' filesep csv_fname];
            fid = fopen(fname,'r');
            for i=1:3
                header{i} = fgetl(fid);
            end
            fclose(fid);
            
            %header = readlines([folder_name filesep 'DLC' filesep csv_fname]);
            parts = strsplit(header{2},',');
            coords = strsplit(header{3},',');
            Nvars = length(parts)-1;
            varNames = cell(Nvars,1);
            for i=2:length(parts)
                varNames{i-1} = [parts{i} '_' coords{i}];
            end            

            M = readmatrix([folder_name filesep 'DLC_new' filesep csv_fname]);
                       
            DLC_raw_table_top = table('Size',[size(M,1), Nvars], ...
                'VariableNames', varNames, ...
                'VariableTypes', string(repmat('double',length(varNames), 1)));
            
            
            DLC_raw_table_top{:,:} = M(:,2:end);
            
            key.n_frames = height(DLC_raw_table_top);
            
            key.time_axis = linspace(0,key.n_frames/frameRate,key.n_frames);            
            key.dlc_raw.top = M(:,2:end);
            key.dlc_raw.top_parts = varNames;   

            disp('Insert success');             
            self.insert(key, 'REPLACE');
        end
    end
end