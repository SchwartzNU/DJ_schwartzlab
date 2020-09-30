function text = add_animalEvent(key, event_type, C)
if nargin<3
    C = dj.conn;
    C.startTransaction;
end
text = sprintf('');
try
    if strcmp(event_type, 'EyeInjection') %need to get or add Eye object
        thisEye = sl.Eye & sprintf('animal_id = %d', key.animal_id) & sprintf('side = "%s"', key.whichEye);
        if ~thisEye.exists
            key_eye.animal_id = key.animal_id;
            key_eye.side = key.whichEye;
            insert(sl.Eye,key_eye);
            text = sprintf('Eye insert successful.\n%s',text);
        end
        key.side = key.whichEye;
        key = rmfield(key,'whichEye');     
    end
    
    if strcmp(event_type, 'SocialBehaviorSession') %need to add stim mice
%         for i=1:length(key.stimAnimals)
%             stimAnimalKeys(i).stimulus_mouse = key.stimAnimals(i);
%             stimAnimalKeys(i).arm = key.stimArms{i};
%         end
        stimAnimalKeys = struct('stimulus_mouse',num2cell(key.stimAnimals),'arm',key.stimArms);
        key = rmfield(key,{'stimAnimals','stimArms'});
        % key = rmfield(key,'stimArms');
    end
        
    insert(feval(sprintf('sl.AnimalEvent%s',event_type)), key);
    
    if strcmp(event_type, 'SocialBehaviorSession') %insert stim mice into part table
        % this_event_id = max(fetchn(sl.AnimalEventSocialBehaviorSession & ['animal_id=' num2str(key.animal_id)], 'event_id'));
        this_event_id = C.query('SELECT max(event_id) as last FROM sl.animal_event_social_behavior_session').last; %reduced overhead 
        [stimAnimalKeys.event_id] = deal(this_event_id);
        insert(sl.AnimalEventSocialBehaviorSessionStimMouse, stimAnimalKeys);
        text = sprintf('Stim mice insert successful.\n%s', text);
%         for i=1:length(stimAnimalKeys)
%             stimAnimalKeys(i).event_id = this_event_id;
%             insert(sl.AnimalEventSocialBehaviorSessionStimMouse, stimAnimalKeys(i));
%             text = sprintf('Stim mouse insert successful.\n%s', text);
%         end
    end
    
    
    text = sprintf('%s insert successful.\n%s', event_type, text);
    if nargin<3
        C.commitTransaction;   
        fprintf(text);
    end 
catch ME    
    fprintf('%s insert failed.\n', event_type);
    if nargin<3
        C.cancelTransaction;
    end
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