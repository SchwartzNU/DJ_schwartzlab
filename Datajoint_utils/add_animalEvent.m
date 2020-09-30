function [] = add_animalEvent(key, event_type)
C = dj.conn;
C.startTransaction
try
    if strcmp(event_type, 'EyeInjection') %need to get or add Eye object
        thisEye = sl.Eye & ['animal_id =' num2str(key.animal_id)] & ['side=' '"' key.whichEye '"'];
        if ~thisEye.exists
            key_eye.animal_id = key.animal_id;
            key_eye.side = key.whichEye;
            insert(sl.Eye,key_eye);
        end
        key.side = key.whichEye;
        key = rmfield(key,'whichEye');        
    end
    
    if strcmp(event_type, 'SocialBehaviorSession') %need to add stim mice
        for i=1:length(key.stimAnimals)
            stimAnimalKeys(i).stimulus_mouse = key.stimAnimals(i);
            stimAnimalKeys(i).arm = key.stimArms{i};
        end
        key = rmfield(key,'stimAnimals');
        key = rmfield(key,'stimArms');
    end
        
    insert(eval(['sl.AnimalEvent' event_type]), key);
    
    if strcmp(event_type, 'SocialBehaviorSession') %insert stim mice into part table
        this_event_id = max(fetchn(sl.AnimalEventSocialBehaviorSession & ['animal_id=' num2str(key.animal_id)], 'event_id'));        
        for i=1:length(stimAnimalKeys)
            stimAnimalKeys(i).event_id = this_event_id;
            insert(sl.AnimalEventSocialBehaviorSessionStimMouse, stimAnimalKeys(i));
            disp('Stim mouse insert successful');
        end
    end
    
    disp('Insert successful');
    C.commitTransaction;    
catch ME    
    disp('Insert failed');
    C.cancelTransaction;
    rethrow(ME)
end
% try 
%     key_AnimalEvent.date = key.date;   
%     key_AnimalEvent.animal_id = key.animal_id;
%     eventsThisDate = sl.AnimalEvent & ['animal_id=' num2str(key.animal_id)] & ['date=' '"' key.date '"'];
%     
%     if eventsThisDate.exists
%         key_AnimalEvent.event_id = max(fetchn(eventsThisDate, 'event_id')) + 1;
%     else
%         key_AnimalEvent.event_id = 1;
%     end
%     insert(sl.AnimalEvent, key_AnimalEvent);    
%     
%     key.event_id = key_AnimalEvent.event_id;
%     if strcmp(event_type, 'EyeInjection') %need to get or add Eye object
%         if strcmp(key.whichEye, 'Left')
%             thisEye = sl.Eye & ['animal_id=' num2str(key.animal_id)] & 'side="L"';
%             if thisEye.exists
%                 key.eye_id = fetch1(thisEye, 'eye_id');
%             else
%                 eyesSoFar = max(fetchn(sl.Eye & ['animal_id=' num2str(key.animal_id)], 'eye_id'));
%                 if isempty(eyesSoFar)
%                     key_eye.eye_id = 1;
%                 else
%                     key_eye.eye_id = eyesSoFar+1;
%                 end
%                 key_eye.animal_id = key.animal_id;
%                 key_eye.side = 'L';
%                 insert(sl.Eye,key_eye);
%                 key.eye_id = key_eye.eye_id;
%             end
%         else %right eye
%             thisEye = sl.Eye & ['animal_id=' num2str(key.animal_id)] & 'side="R"';
%             if thisEye.exists
%                 key.eye_id = fetch1(thisEye, 'eye_id');
%             else
%                 eyesSoFar = max(fetchn(sl.Eye & ['animal_id=' num2str(key.animal_id)], 'eye_id'));
%                 if isempty(eyesSoFar)
%                     key_eye.eye_id = 1;
%                 else
%                     key_eye.eye_id = eyesSoFar+1;
%                 end
%                 key_eye.animal_id = key.animal_id;
%                 key_eye.side = 'R';
%                 insert(sl.Eye,key_eye);   
%                 key.eye_id = key_eye.eye_id;
%             end
%         end
%         
%         key = rmfield(key,'whichEye');        
%     end
%     insert(eval(['sl.AnimalEvent' event_type]), key);        
%     disp('Insert successful');
%     if strcmp(event_type, 'MoveCage')
%         %need an extra command to do the move
%         thisMove = sl.AnimalEventMoveCage & key;
%         thisMove.doMove();
%     end        
%     C.commitTransaction;    
% catch ME    
%     errordlg('Insert failed');
%     C.cancelTransaction;
%     rethrow(ME)
% end