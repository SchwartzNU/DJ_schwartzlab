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
%}

classdef BehaviorSessionTrackingData < dj.Imported
     methods(Access=protected)
        function makeTuples(self, key)  
            C = dj.conn;
            if strcmp(C.host, 'localhost') 
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
            load([foldername filesep 'full_data.mat']);
            Nframes = length(bino_gaze.gaze.outer_wall.left);
            frameRate = 15; %Hz, TODO, read this in from calibration;
            
            key.timeAxis = linspace(0,Nframes/frameRate,Nframes);            
            key.dlc_raw = DLC_tracking;
            key.head_position_arc = bino_gaze.body_position_arc';
            key.body_speed = bino_gaze.speed';
            key.window_visibility = bino_gaze.window_visibility;
            key.gaze_bino_outer = bino_gaze.gaze.outer_wall.left';
            key.cumulative_gaze_bino = bino_gaze.accumulative_gaze.outer_wall.left';
            key.gaze_left_outer = mono_gaze.gaze.outer_wall.left';
            key.cumulative_gaze_left = mono_gaze.accumulative_gaze.outer_wall.left;
            key.gaze_right_outer = mono_gaze.gaze.outer_wall.right';
            key.cumulative_gaze_right = mono_gaze.accumulative_gaze.outer_wall.right;
            key.cumulative_body = bino_gaze.accumulative_body_position.outer_wall;
                        
            self.insert(key);
        end
    end
end