%{
# Locations of calibration points from top camera

-> sln_animal.SocialBehaviorSession
---
center_x : float #pixel center of arena
center_y : float
inner_wall_radius : float # pixels
window_a_start_ang : float # radians
window_a_end_ang : float
window_b_start_ang : float
window_b_end_ang : float
window_c_start_ang : float
window_c_end_ang : float
window_a_start : longblob #2 element (x,y) vector of pixel position 
window_a_end : longblob #2 element (x,y) vector of pixel position 
window_b_start : longblob #2 element (x,y) vector of pixel position 
window_b_end : longblob #2 element (x,y) vector of pixel position 
window_c_start : longblob #2 element (x,y) vector of pixel position 
window_c_end : longblob #2 element (x,y) vector of pixel position 
%}

classdef TopCameraCalibration < dj.Imported
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

            calibration_file = [folder_name filesep 'calibration_top.csv'];

            if ~exist(calibration_file, 'file')
                disp('Top camera calibration csv not found');
                return;
            end

            T = readtable(calibration_file);
            key.center_x = T.Center(1);
            key.center_y = T.Center(2);
            key.inner_wall_radius = T.radius(1);
            key.window_a_start = T.windowA_start;
            key.window_a_end = T.windowA_end;
            key.window_b_start = T.windowB_start;
            key.window_b_end = T.windowB_end;
            key.window_c_start = T.windowC_start;
            key.window_c_end = T.windowC_end;
            
            temp = T.windowA_start - T.Center;
            [theta(1), ~] = cart2pol(temp(1), temp(2));
            temp = T.windowA_end - T.Center;
            [theta(2), ~] = cart2pol(temp(1), temp(2));
            theta = sort(theta, 'ascend');
            key.window_a_start_ang = theta(1);
            key.window_a_end_ang = theta(2);
            
            temp = T.windowB_start - T.Center;
            [theta(1), ~] = cart2pol(temp(1), temp(2));
            temp = T.windowB_end - T.Center;
            [theta(2), ~] = cart2pol(temp(1), temp(2));
            theta = sort(theta, 'ascend');
            key.window_b_start_ang = theta(1);
            key.window_b_end_ang = theta(2);

            temp = T.windowC_start - T.Center;
            [theta(1), ~] = cart2pol(temp(1), temp(2));
            temp = T.windowC_end - T.Center;
            [theta(2), ~] = cart2pol(temp(1), temp(2));
            theta = sort(theta, 'ascend');
            key.window_c_start_ang = theta(1);
            key.window_c_end_ang = theta(2);

            disp('Insert success');             
            self.insert(key, 'REPLACE');
        end
    end
end