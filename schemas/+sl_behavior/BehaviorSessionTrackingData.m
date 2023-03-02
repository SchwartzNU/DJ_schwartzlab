%{
# Behavior session tracking data

-> sln_animal.SocialBehaviorSession
---
time_axis : longblob            # vector with units of seconds 
dlc_raw : longblob              # struct with dlc positions and confidence data
head_position_arc : longblob    # vector, units of radians
body_speed : longblob           # vector 1 element shorter than time_axis, units of pixels per second
window_visibility : longblob    # logical vector Nframes x 3 columns marking times the animal is visible to windows A,B,C
gaze_bino_outer : longblob      # vector of estimated binocular gaze positions along the outer wall (radians)
cumulative_gaze_bino: longblob  # vector Nframes-1 * 3 of the number of frames gazing at each window
gaze_left_outer : longblob      # vector of estimated left eye gaze positions along the outer wall (radians) assumes 32 degree eye angle
cumulative_gaze_left: longblob  # vector Nframes-1 * 3 of the number of frames spent gazing of each window, left eye
gaze_right_outer : longblob     # vector of estimated right eye gaze positions along the outer wall (radians)
cumulative_gaze_right: longblob # vector Nframes-1 * 3 of the number of frames spent gazing of each window, right eye
cumulative_body: longblob       # vector Nframes-1 * 3 of the number of frames body center is in front of each window
nose_window_dist : longblob     # vector Nframes-1 * 3 of the number nose distance from each window
squeak_times : longblob         # vector of identifies squeak times (in seconds)
window_crossings_in_frame : longblob     # vector of frame times that begin window crossings
window_crossings_out_frame  : longblob   # vector of frame times that end window crossings
window_crossings_win  : longblob         # which window was crossed for each event
window_crossings_type : longblob         # double back or straight through for each crossing
snout_x                : longblob         # snout position, top camera X, interpolated where we are missing data
snout_y                : longblob         # snout position, top camera Y, interpolated where we are missing data
%}

classdef BehaviorSessionTrackingData < dj.Imported
     methods(Access=protected)
        function makeTuples(self, key)  
            C = dj.conn;
            if strcmp(C.host, '127.0.0.1:3306') 
               rootFolder = '/mnt/fsmresfiles/behavior';
            elseif exist(getenv('SERVER_ROOT'), 'dir')
               rootFolder = [getenv('SERVER_ROOT') filesep 'Behavior'];
            else
               disp('Aborting BehaviorSessionTrackingData import: Behavior folder not found');
            end
           
            folder_name = matchSessionToBehaviorFolder(key.event_id, rootFolder);
            if isempty(folder_name) %no folder for this one, so don't add anything
               return; 
            end
            try
                load([folder_name filesep 'full_data.mat']);
            catch
                disp('Aborting BehaviorSessionTrackingData import: fullData.nmat not found in behavior folder');
                return;
            end
            Nframes = length(bino_gaze.gaze.outer_wall.left);
            frameRate = 15; %Hz, TODO, read this in from calibration;
            scoreThreshold = 0.85; %for DLC tracking from top camera, TODO, read this in from calibration;
            %todo: find the right camera correctly!
            if isfield(DLC_tracking, 'camera_3')
                camField = 'camera_1';
            else
                camField = 'camera_0';
            end
            
            camera_serial_number = '17391304';
            dlc_files = dir([folder_name filesep 'DLC']);
            dlc_filenames = {dlc_files.name};
            
            ind = find(startsWith(dlc_filenames, ['camera_' camera_serial_number]) ...
                & endsWith(dlc_filenames, '.csv'));
            
            csv_fname = dlc_filenames{ind};            
            fname = [folder_name filesep 'DLC' filesep csv_fname];
            fid = fopen(fname,'r');
            for i=1:4
                header{i} = fgetl(fid);
            end
            fclose(fid);
            
            %header = readlines([folder_name filesep 'DLC' filesep csv_fname]);
            parts = strsplit(header{3},',');
            coords = strsplit(header{4},',');
            Nvars = length(parts)-1;
            varNames = cell(Nvars,1);
            for i=2:length(parts)
                varNames{i-1} = [parts{i} '_' coords{i}];
            end
            
            M = readmatrix([folder_name filesep 'DLC' filesep csv_fname]);
                        
            DLC_raw_table_top = table('Size',[Nframes, Nvars], ...
                'VariableNames', varNames, ...
                'VariableTypes', string(repmat('double',24, 1)));
            
            DLC_raw_table_top{:,:} = M(:,2:end);
            
            key.time_axis = linspace(0,Nframes/frameRate,Nframes);            
            %key.dlc_raw = DLC_tracking;            
            key.dlc_raw.top = M(:,2:end);
            key.dlc_raw.top_parts = varNames;            
            
            key.head_position_arc = bino_gaze.body_position_arc';
            key.body_speed = bino_gaze.speed';
            key.window_visibility = bino_gaze.window_visibility;
            key.gaze_bino_outer = bino_gaze.gaze.outer_wall.left';
            key.cumulative_gaze_bino = bino_gaze.accumulative_gaze.outer_wall.left;
            key.gaze_left_outer = mono_gaze.gaze.outer_wall.left';
            key.cumulative_gaze_left = mono_gaze.accumulative_gaze.outer_wall.left;
            key.gaze_right_outer = mono_gaze.gaze.outer_wall.right';
            key.cumulative_gaze_right = mono_gaze.accumulative_gaze.outer_wall.right;
            key.cumulative_body = bino_gaze.accumulative_body_position.outer_wall;
            key.nose_window_dist(:,1) = bino_gaze.nose_window_distance.window_A';
            key.nose_window_dist(:,2) = bino_gaze.nose_window_distance.window_B';
            key.nose_window_dist(:,3) = bino_gaze.nose_window_distance.window_C';
            %snoutX = DLC_tracking.(camField).snout_x;
            %snoutY = DLC_tracking.(camField).snout_y;
            %snout_likelihood = DLC_tracking.(camField).snout_likelihood;            
            
            snoutX = DLC_raw_table_top.nose_x;
            snoutY = DLC_raw_table_top.nose_y;
            snout_likelihood = DLC_raw_table_top.nose_likelihood;
            
            snoutX(snout_likelihood < scoreThreshold) = nan;
            nanx = isnan(snoutX);
            t = 1:numel(snoutX);
            snoutX(nanx) = interp1(t(~nanx), snoutX(~nanx), t(nanx),'linear','extrap');
                        
            snoutY(snout_likelihood < scoreThreshold) = nan;
            nany = isnan(snoutY);
            t = 1:numel(snoutY);
            snoutY(nany) = interp1(t(~nany), snoutX(~nany), t(nany),'linear','extrap');

            key.snout_x = snoutX';
            key.snout_y = snoutY';
            
            %now look for 3D table and read that in
            csv_fname = 'output_3d_data_kalman.csv';
            try
                fname = [folder_name filesep 'DLC' filesep csv_fname];
                fid = fopen(fname,'r');
                for i=1:2
                    header{i} = fgetl(fid);
                end
                fclose(fid);

                %header = readlines([folder_name filesep 'DLC' filesep csv_fname]);
                parts = strsplit(header{1},',');
                coords = strsplit(header{2},',');
                Nvars = length(parts);
                varNames = cell(Nvars,1);
                for i=1:length(parts)
                    varNames{i} = [parts{i} '_' coords{i}];
                end
                key.dlc_raw.threeD = readmatrix([folder_name filesep 'DLC' filesep csv_fname]);
                key.dlc_raw.threeD_parts = varNames;

                %truncate 2D to match the number of frames in the 3D
                Nframes = size(key.dlc_raw.threeD, 1);
                key.dlc_raw.top = key.dlc_raw.top(1:Nframes,:);
                key.snout_x = key.snout_x(1:Nframes);
                key.snout_y = key.snout_y(1:Nframes);
                key.time_axis = key.time_axis(1:Nframes);
            catch
                disp('3D output not found, skipping')
            end

            if isfield(bino_gaze,'window_crossings')
                Ncrossings = length(bino_gaze.window_crossings.in_frame);
                if Ncrossings
                    key.window_crossings_in_frame = zeros(Ncrossings,1);
                    key.window_crossings_out_frame = zeros(Ncrossings,1);
                    key.window_crossings_win = cell(Ncrossings,1);
                    key.window_crossings_type = cell(Ncrossings,1);
                    
                    for i=1:Ncrossings
                        key.window_crossings_in_frame(i) = bino_gaze.window_crossings.in_frame(i);
                        key.window_crossings_out_frame(i) = bino_gaze.window_crossings.out_frame(i);
                        key.window_crossings_win{i} = bino_gaze.window_crossings.window(i);
                        key.window_crossings_type{i} = deblank(bino_gaze.window_crossings.type(i,:));
                    end
                else
                    key.window_crossings_in_frame = 0;
                    key.window_crossings_out_frame = 0;
                    key.window_crossings_win = {'none'};
                    key.window_crossings_type = {'none'};
                end
                
            else
                key.window_crossings_in_frame = 0;
                key.window_crossings_out_frame = 0;
                key.window_crossings_win = {'missing'};
                key.window_crossings_type = {'missing'};
            end
            
            %TEMP HACK: no squeaks for now
            key.squeak_times = 'missing';

            %if exist('squeaks_time','var')
            %    key.squeak_times = squeaks_time.('B&K_audio_squeaks');           
            %else
            %    key.squeak_times = 'missing';
            %end        
                
            self.insert(key, 'REPLACE');
        end
    end
end