%{
# Manual calibration data from the top camera

-> sln_animal.SocialBehaviorSession
---
center_point_x : int unsigned # x pixel of arena center 
center_point y : int unsigned # y pixel of arena center
inner_wall_radius : float # pixels
window_a : longblob # 2 x 2 matrix with the coordinates of the endpoints of window A
window_b : longblob # 2 x 2 matrix with the coordinates of the endpoints of window B
window_c : longblob # 2 x 2 matrix with the coordinates of the endpoints of window C
%}

classdef TopCameraManualCalibration < dj.Imported
    methods(Access=protected)
        function makeTuples(self, key)
            thisSession = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('event_id=%d',key.event_id);
            
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

            

            %disp('Insert success');
            %self.insert(key, 'REPLACE');
        end
    end
end