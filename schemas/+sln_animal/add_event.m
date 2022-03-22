function [inserted, text] = add_event(key, event_type, C)
if nargin<3
    C = dj.conn;
    C.startTransaction;
end
inserted = false;
text = sprintf('');
try
    if isfield(key, 'animal_id')
        %event must not occur before birth date
        dob = fetch1(sln_animal.Animal & sprintf('animal_id=%d', key.animal_id), 'dob');
        if ~isempty(dob) && datetime(key.date) < datetime(dob)
            error('AnimalEvent cannot occur before the animal dob');
        end
    end
    
    if strcmp(event_type, 'EyeInjection') %need to get or add Eye object
        thisEye = sln_animal.Eye & sprintf('animal_id = %d', key.animal_id) & sprintf('side = "%s"', key.whichEye);
        if ~thisEye.exists
            key_eye.animal_id = key.animal_id;
            key_eye.side = key.whichEye;
            insert(sln_animal.Eye,key_eye);
            text = sprintf('Eye insert successful.\n%s',text);
        end
        key.side = key.whichEye;
        key = rmfield(key,'whichEye');     
    end
    
%     if strcmp(event_type, 'PairBreeders') %need to make breeding cage first
%         if isempty(key.cage_number)
%             error('Must enter a cage number.'); 
%         end
%         key_breedingCage = struct;
%         key_breedingCage.cage_number = key.cage_number;
%         insert(sl.BreedingCage, key_breedingCage);        
%         
%         %then do cage assignment for both animals
%         key_male_move = struct;
%         key_male_move.animal_id = key.male_id;
%         key_male_move.cage_number = key.cage_number;
%         key_male_move.room_number = key.room_number;
%         key_male_move.cause = 'set as breeder';
%         key_male_move.date = key.date;
%         key_male_move.user_name = key.user_name;        
%         insert(sl.AnimalEventAssignCage, key_male_move);
%         
%         key_female_move = key_male_move;
%         key_female_move.animal_id = key.female_id;
%         insert(sl.AnimalEventAssignCage, key_female_move);
%         
%         %activate breeding cage
%         key_activate = struct;
%         key_activate.cage_number = key.cage_number;
%         key_activate.date = key.date;
%         key_activate.user_name = key.user_name;
%         insert(sl.AnimalEventActivateBreedingCage, key_activate);
%     end
    
%     if strcmp(event_type, 'SeparateBreeders') %need to deactivate breeding cage then move animals\
%         %special case if female has the same cage as the current cage
%         %don't deactivate
%         if isempty(key.new_cage_male) || isempty(key.new_cage_female)
%             disp('Must include cage numbers');
%             error('Missing cage number for either male or female mouse');
%         end
%         if strcmp(key.cage_number, key.new_cage_female)
%             %do nothing
%             disp('breeding cage not deactivated');
%         else
%             %deactivate breeding cage
%             key_deactivate = struct;
%             key_deactivate.cage_number = key.cage_number;
%             key_deactivate.date = key.date;
%             key_deactivate.user_name = key.user_name;
%             insert(sl.AnimalEventDeactivateBreedingCage, key_deactivate);
%         end
%             
%         %then do cage assignment for both animals
% 
%         %special case if male is absent don't move
%         if key.male_id == 0
%             %do nothing
%             disp('absent male breeder not moved');
%         else  %else do move
%             key_male_move = struct;
%             key_male_move.animal_id = key.male_id;
%             key_male_move.cage_number = key.new_cage_male;
%             key_male_move.room_number = key.new_room_male;
%             key_male_move.cause = 'separated breeder';
%             key_male_move.date = key.date;
%             key_male_move.user_name = key.user_name;
%             insert(sl.AnimalEventAssignCage, key_male_move);
%         end
%         
%         if strcmp(key.cage_number, key.new_cage_female)
%             %do nothing
%             disp('female not moved');
%         else
%             key_female_move = struct;
%             key_female_move.date = key.date;
%             key_female_move.user_name = key.user_name;
%             key_female_move.animal_id = key.female_id;
%             key_female_move.cause = 'separated breeder';
%             key_female_move.cage_number = key.new_cage_female;
%             key_female_move.room_number = key.new_room_female;
%             insert(sl.AnimalEventAssignCage, key_female_move);
%         end
%         
%         if strcmp(key.cage_number, key.new_cage_female)
%             %do nothing
%             disp('female not retired');
%         else %retire female
%             key_retire_female = struct;
%             key_retire_female.animal_id = key.female_id;
%             key_retire_female.date = key.date;
%             key_retire_female.user_name = key.user_name;
%             insert(sl.AnimalEventRetireAsBreeder, key_retire_female);
%         end
%         
%         if key.male_id == 0
%             %do nothing
%             disp('absent male not retired');
%         else  %else retire male
%             key_retire_male = struct;
%             key_retire_male.animal_id = key.male_id;
%             key_retire_male.date = key.date;
%             key_retire_male.user_name = key.user_name;
%             insert(sl.AnimalEventRetireAsBreeder, key_retire_male);
%         end
%         
%         
% %         %then retire each as breeders
% %         key_retire_male = struct;
% %         key_retire_male.animal_id = key.male_id;
% %         key_retire_male.date = key.date;
% %         key_retire_male.user_name = key.user_name;       
% %         insert(sl.AnimalEventRetireAsBreeder, key_retire_male);
% %         
% %         key_retire_female = key_retire_male;
% %         key_retire_female.animal_id = key.female_id;
% %         insert(sl.AnimalEventRetireAsBreeder, key_retire_female);
%         
%     end
    
    if strcmp(event_type, 'SocialBehaviorSession') %need to add stim mice
        stimAnimalKeys = struct('stim_type',key.stimTypes,'arm',key.stimArms);
        for i=1:length(stimAnimalKeys)
            if key.stimIDs(i)
                stimAnimalKeys(i).stimulus_animal_id = key.stimIDs(i);
            else
                stimAnimalKeys(i).stimulus_animal_id = nan;
            end
        end
        key = rmfield(key,{'stimTypes','stimArms','stimIDs'});    
    end
    
    if strcmp(event_type, 'Tag')
        if isfield(key,'do_tag') && ~key.do_tag
            if ~strcmp(key.tag_ear,'None') || ~strcmp(key.punch,'None') || ~isnan(key.tag_id)
                disp('Must mark animal as tagged if inserting tag or punch information');
                error('Animal not marked as tagged');
            else
                inserted = false;                
                if nargin<3
                    C.cancelTransaction;
                end
                return
            end
        end
        if strcmp(key.tag_ear,'None') && strcmp(key.punch,'None')
            disp('Animal must be either tagged or punched to enter a tag event');
            error('Missing tag and punch info');
        elseif (strcmp(key.tag_ear,'None') && ~isnan(key.tag_id)) || (~strcmp(key.tag_ear,'None') && isnan(key.tag_id))
            disp('Animal must either have both a tag ear and tag # or have neither');
            error('Missing tag info');
        end
    end
    
    if strcmp(event_type, 'AssignCage')
        if isempty(key.cage_number)
            disp('Must assign a cage number when moving an animal');
            error('Missing cage number');
        end
    end
    
    %MAIN INSERT of this event type
    key = insert(sln_animal.AnimalEvent, key);
    insert(feval(sprintf('sln_animal.%s',event_type)), key);

%     if strcmp(event_type, 'SeparateBreeders') && key.male_id == 0
%         %special case, no SeparateBreeders event insert for male==0
%     else
%         insert(feval(sprintf('sl.AnimalEvent%s',event_type)), key);
%     end
%     
    if strcmp(event_type, 'SocialBehaviorSession') %insert stim mice into part table
        this_event_id = max(fetchn(sln_animal.SocialBehaviorSession & ['animal_id=' num2str(key.animal_id)], 'event_id'));
        [stimAnimalKeys.event_id] = deal(this_event_id);
        insert(sln_animal.SocialBehaviorSessionStimulus, stimAnimalKeys);
        text = sprintf('Stimulus insert successful.\n%s', text);
    end
        
    text = sprintf('%s insert successful.\n%s', event_type, text);
    if nargin<3
        C.commitTransaction;   
        fprintf(text);
        inserted = true;
    end 
catch ME    
    fprintf('%s insert failed.\n', event_type);
    if nargin<3
        C.cancelTransaction;
    end
    inserted = false;
    rethrow(ME)
end
