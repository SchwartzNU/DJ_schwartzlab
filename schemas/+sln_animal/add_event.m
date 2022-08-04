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
        thisEye = sln_animal.Eye & sprintf('animal_id = %d', key.animal_id) & sprintf('side = "%s"', key.side);
        if ~thisEye.exists
            key_eye.animal_id = key.animal_id;
            key_eye.side = key.side;
            insert(sln_animal.Eye,key_eye);
            text = sprintf('Eye insert successful.\n%s',text);
        end
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
        %make the new cage each time and replace the old one
        thisCage = sln_animal.Cage & sprintf('cage_number=%d', key.cage_number);
        if ~thisCage.exists %need to make the cage
            if strcmp(key.cause,'set as breeder')
                key_cage.is_breeding = 'T';
            else
                key_cage.is_breeding = 'F';
            end
            key_cage.cage_number = key.cage_number;
            insert(sln_animal.Cage,key_cage);
        end
    end
    
    %MAIN INSERT of this event type    
    if strcmp(event_type, 'SocialBehaviorSession')
        old_event_id = key.event_id;
        key = rmfield(key,'event_id');
    end

    key
    key = insert(sln_animal.AnimalEvent, key)
    insert(feval(sprintf('sln_animal.%s',event_type)), key);
    %disp('did main insert')
%     if strcmp(event_type, 'SeparateBreeders') && key.male_id == 0
%         %special case, no SeparateBreeders event insert for male==0
%     else
%         insert(feval(sprintf('sl.AnimalEvent%s',event_type)), key);
%     end
%     
    if strcmp(event_type, 'SocialBehaviorSession') %insert stim mice into part table
        this_event_id = key.event_id;

        stims = fetch(sl.AnimalEventSocialBehaviorSessionStimulus & sprintf('event_id=%d',old_event_id), '*');
        stims = rmfield(stims,'event_id');
        [stims.event_id] = deal(this_event_id);
        insert(sln_animal.SocialBehaviorSessionStimulus, stims);
        text = sprintf('Stimulus insert successful.\n%s', text);
        key = rmfield(key,'event_id');        
    end
        
    text = sprintf('%s insert successful.\n%s', event_type, text);
    if nargin<3
        if C.inTransaction
            C.commitTransaction;
        end
        fprintf(text);
        inserted = true;
    end 
catch ME    
    fprintf('%s insert failed.\n', event_type);
    if nargin<3
        C.cancelTransaction;
    end
    inserted = false;
    text = ME.message;
    disp(text);
end
