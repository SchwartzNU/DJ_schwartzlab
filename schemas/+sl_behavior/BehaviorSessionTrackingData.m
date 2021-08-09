%{
# Behavior session tracking data

-> sl.AnimalEventSocialBehaviorSession
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
            load([folder_name filesep 'full_data.mat']);
            Nframes = length(bino_gaze.gaze.outer_wall.left);
            frameRate = 15; %Hz, TODO, read this in from calibration;
            scoreThreshold = 0.85; %for DLC tracking from top camera, TODO, read this in from calibration;
            
            key.time_axis = linspace(0,Nframes/frameRate,Nframes);            
            key.dlc_raw = DLC_tracking;
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
            snoutX = DLC_tracking.camera_1.snout_x;
            snoutY = DLC_tracking.camera_1.snout_y;
            snout_likelihood = DLC_tracking.camera_1.snout_likelihood;            
            
            snoutX(snout_likelihood < scoreThreshold) = nan;
            nanx = isnan(snoutX);
            t = 1:numel(snoutX);
            snoutX(nanx) = interp1(t(~nanx), snoutX(~nanx), t(nanx));
                        
            snoutY(snout_likelihood < scoreThreshold) = nan;
            nany = isnan(snoutY);
            t = 1:numel(snoutY);
            snoutY(nany) = interp1(t(~nany), snoutX(~nany), t(nany));

            key.snout_x = snoutX';
            key.snout_y = snoutY';
            
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
            
            if exist('squeaks_time','var')
                key.squeak_times = squeaks_time.('B&K_audio_squeaks');           
            else
                key.squeak_times = 'missing';
            end        
                
            self.insert(key, 'REPLACE');
        end
    end
end