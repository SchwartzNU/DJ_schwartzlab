%{
# DeepSqueeks USV Calls Data

-> sln_animal.SocialBehaviorSession
---
call_times : longblob    # call times in seconds
call_frames : longblob   # call times in frames  
n_calls : int unsigned   # number of calls
call_types : longblob   # type number of each call
n_adult_calls : int unsigned    # number of adult calls
n_pup_calls : int unsigned      # number of pup calls
%}

classdef Squeaks < dj.Imported
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

            squeak_mat_fname = sprintf('%d.mat',key.event_id);
            fname = [folder_name filesep squeak_mat_fname];
            if ~exist(fname,'file')
                fprintf('Squeak data for session %d not found.\n', key.event_id);
                return;
            end

            frameRate = 15; %Hz, TODO, read this in from calibration;

            load(fname,'Calls');
            key.n_calls = height(Calls);
            key.call_times = [0];
            key.call_frames = [0];
            key.call_types = [0];
            key.n_adult_calls = 0;
            key.n_pup_calls = 0;
            if key.n_calls > 0                
                key.call_times = Calls.Box(:,1);
                key.call_frames = round(key.call_times * frameRate);
                types = string(Calls.Type);
                types(strcmp(types,'USV')) = '0';
                types_int = str2num(char(types));
                key.call_types = types_int;
                key.n_adult_calls = sum(key.call_types>4);
                key.n_pup_calls = sum(key.call_types<=4);
            end
            
            disp('Insert success');             
            self.insert(key, 'REPLACE');
        end
    end
end