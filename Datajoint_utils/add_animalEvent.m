function [inserted, text] = add_animalEvent(key, event_type, C)
if nargin<3
    C = dj.conn;
    C.startTransaction;
end
inserted = false;
text = sprintf('');
try
    if isfield(key, 'animal_id')
        %event must not occur before birth date
        dob = fetch1(sl.Animal & sprintf('animal_id=%d', key.animal_id), 'dob');
        if ~isempty(dob) && datetime(key.date) < datetime(dob)
            error('AnimalEvent cannot occur before the animal dob');
        end
    end
    
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
    
    if strcmp(event_type, 'PairBreeders') %need to make breeding cage first 
        key_breedingCage = struct;
        key_breedingCage.cage_number = key.cage_number;
        insert(sl.BreedingCage, key_breedingCage);        
        
        %then do cage assignment for both animals
        key_male_move = struct;
        key_male_move.animal_id = key.male_id;
        key_male_move.cage_number = key.cage_number;
        key_male_move.room_number = key.room_number;
        key_male_move.cause = 'set as breeder';
        key_male_move.date = key.date;
        key_male_move.user_name = key.user_name;        
        insert(sl.AnimalEventAssignCage, key_male_move);
        
        key_female_move = key_male_move;
        key_female_move.animal_id = key.female_id;
        insert(sl.AnimalEventAssignCage, key_female_move);
        
        %activate breeding cage
        key_activate = struct;
        key_activate.cage_number = key.cage_number;
        key_activate.date = key.date;
        key_activate.user_name = key.user_name;
        insert(sl.AnimalEventActivateBreedingCage, key_activate);
    end
    
    if strcmp(event_type, 'SeparateBreeders') %need to deactivate breeding cage then move animals\
        %special case if female has the same cage as the current cage
        %don't deactivate
        if strcmp(key.cage_number, key.new_cage_female)
            %do nothing
            disp('breeding cage not deactivated');
        else
            %deactivate breeding cage
            key_deactivate = struct;
            key_deactivate.cage_number = key.cage_number;
            key_deactivate.date = key.date;
            key_deactivate.user_name = key.user_name;
            insert(sl.AnimalEventDeactivateBreedingCage, key_deactivate);
        end
            
        %then do cage assignment for both animals
        key_male_move = struct;
        key_male_move.animal_id = key.male_id;
        key_male_move.cage_number = key.new_cage_male;
        key_male_move.room_number = key.new_room_male;
        key_male_move.cause = 'separated breeder';
        key_male_move.date = key.date;
        key_male_move.user_name = key.user_name;        
        insert(sl.AnimalEventAssignCage, key_male_move);
        
        if strcmp(key.cage_number, key.new_cage_female)
            %do nothing
            disp('female not moved');
        else
            key_female_move = key_male_move;
            key_female_move.animal_id = key.female_id;
            key_female_move.cage_number = key.new_cage_female;
            key_female_move.room_number = key.new_room_female;
            insert(sl.AnimalEventAssignCage, key_female_move);
        end
        
%         %then retire each as breeders
%         key_retire_male = struct;
%         key_retire_male.animal_id = key.male_id;
%         key_retire_male.date = key.date;
%         key_retire_male.user_name = key.user_name;       
%         insert(sl.AnimalEventRetireAsBreeder, key_retire_male);
%         
%         key_retire_female = key_retire_male;
%         key_retire_female.animal_id = key.female_id;
%         insert(sl.AnimalEventRetireAsBreeder, key_retire_female);
        
    end
    
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

    insert(feval(sprintf('sl.AnimalEvent%s',event_type)), key);
    
    if strcmp(event_type, 'SocialBehaviorSession') %insert stim mice into part table
        this_event_id = max(fetchn(sl.AnimalEventSocialBehaviorSession & ['animal_id=' num2str(key.animal_id)], 'event_id'));
        [stimAnimalKeys.event_id] = deal(this_event_id);
        insert(sl.AnimalEventSocialBehaviorSessionStimulus, stimAnimalKeys);
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
