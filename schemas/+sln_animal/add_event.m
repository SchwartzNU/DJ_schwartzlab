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
%             if strcmp(key.cause,'set as breeder')
%                 key_cage.is_breeding = 'T';
%             else
%                 key_cage.is_breeding = 'F';
%             end
            key_cage.cage_number = key.cage_number;
            insert(sln_animal.Cage,key_cage);
        end
        
        if isfield(key,'room_number')
            curr_room = sln_animal.CageAssignRoom.current & struct('cage_number',key.cage_number);
            if count(curr_room) == 0 || ~strcmp(fetch1(curr_room, 'room_number'), key.room_number)
                key_room = rmfield(key,{'notes','animal_id','cause'});
                insert(sln_animal.CageAssignRoom, key_room);
            end
            key = rmfield(key,'room_number');
        end
    end
    
    %MAIN INSERT of this event type    
    if strcmp(event_type, 'SocialBehaviorSession')
        old_event_id = key.event_id;
        key = rmfield(key,'event_id');
    end

    key
    [key,animal_id] = insert(sln_animal.AnimalEvent, key)
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
    
    
    if strcmp(event_type, 'GenotypeResult') %update the genotype of the animal
        % Note: currently only works for diploid species
        
    %         [existing_ids, existing_names] = fetchn(sln_animal.Genotype & struct('animal_id',animal_id,'locus_name',key.locus_name),'allele_id', 'allele_name');
       
        
        locus = struct('locus_name',key.locus_name);
        parents = proj(proj(sln_animal.Animal & struct('animal_id',animal_id),'source_id') * sln_animal.BreedingPair, '*','animal_id->child_id');
        
        dad_gt = proj(parents,'male_id') * proj(sln_animal.Genotype & locus,'animal_id->male_id','allele_name');
        dad_gt = aggr((proj(sln_animal.Animal) & proj(dad_gt,'male_id->animal_id'))* proj(sln_animal.Allele) * (proj(sln_animal.GeneLocus) & locus), proj(sln_animal.Allele) * proj(dad_gt,'male_id->animal_id','source_id->tmp','allele_name'),'count(*)->copy_number');
        dad_copy_number = fetch1(aggr((proj(sln_animal.Animal) & proj(parents,'male_id->animal_id')) * proj(sln_animal.GeneLocus & locus), dad_gt, 'sum(copy_number)->counts'), 'counts');
        
        mom_gt = proj(parents,'female_id') * proj(sln_animal.Genotype & locus,'animal_id->female_id','allele_name');
        mom_gt = aggr((proj(sln_animal.Animal) & proj(mom_gt,'female_id->animal_id'))* proj(sln_animal.Allele) * (proj(sln_animal.GeneLocus) & locus), proj(sln_animal.Allele) * proj(mom_gt,'female_id->animal_id','source_id->tmp','allele_name'),'count(*)->copy_number');
        mom_copy_number = fetch1(aggr((proj(sln_animal.Animal) & proj(parents,'female_id->animal_id')) * proj(sln_animal.GeneLocus & locus), mom_gt, 'sum(copy_number)->counts'), 'counts');

       gks = fetch(sln_animal.Genotype & struct('animal_id',animal_id,'locus_name',key.locus_name),'*');
       if ~isempty(gks)
         gks = struct2table(gks,'asarray',1);
       else
           gks = cell2table(cell(0,numel(fieldnames(gks))),'variablenames', fieldnames(gks));
       end
         existing = 1:size(gks,1);
%          if ~strcmpi(key.allele1, 'ambiguous')
%                gks = [gks; {animal_id, key.locus_name, size(gks,1)+1, key.event_id, key.allele1, nan}];
%          end
%          if ~strcmpi(key.allele2, 'ambiguous')
%                gks = [gks; {animal_id, key.locus_name, size(gks,1)+1, key.event_id, key.allele2, nan}];
%          end
         
        if ~strcmpi(key.allele1,'Ambiguous') && ~any(strcmp(key.allele1, gks(existing,:).allele_name)) %this is a new entry
%             gks = [gks; {animal_id, key.locus_name, size(gks,1)+1, key.event_id, key.allele1, ''}];
            gks = [gks; {animal_id, key.locus_name, size(gks,1)+1, key.event_id, key.allele1}];
            
%             %inheritance
%             mom_carrier = count(mom_gt & struct('allele_name', key.allele1) & 'copy_number>0');
%             dad_carrier = count(dad_gt & struct('allele_name', key.allele1) & 'copy_number>0');
% 
%             if mom_carrier && ~isnan(dad_copy_number) && dad_copy_number==2 && ~dad_carrier
%                 %we know for certain that the allele came from mom
%                 gks.inheritance{end} = 'maternal';
%             elseif dad_carrier && ~isnan(mom_copy_number) && mom_copy_number==2 && ~mom_carrier
%                 %same but for dad
%                 gks.inheritance{end} = 'paternal';
%             elseif any(strcmpi(key.allele1, gks(existing,:).allele_name)) || strcmpi(key.allele2, key.allele1)
%                 % animal is homozygous, we will assign allele1 to mom
%                 % and allele2 to dad
%                 gks.inheritance{end} = 'maternal';
%             end
        end
        
        if ~strcmpi(key.allele2,'Ambiguous') && (~any(strcmp(key.allele2, gks(existing,:).allele_name)) || (nnz(strcmp(gks(existing,:).allele_name, key.allele2)) == 1 && strcmpi(key.allele1, key.allele2))) %this is a new entry
%             gks = [gks; {animal_id, key.locus_name, size(gks,1)+1, key.event_id, key.allele2, ''}];
            gks = [gks; {animal_id, key.locus_name, size(gks,1)+1, key.event_id, key.allele2}];
%             %inheritance
%             mom_carrier = count(mom_gt & struct('allele_name', key.allele2) & 'copy_number>0');
%             dad_carrier = count(dad_gt & struct('allele_name', key.allele2) & 'copy_number>0');
% 
%             if mom_carrier && ~isnan(dad_copy_number) && dad_copy_number==2 && ~dad_carrier
%                 %we know for certain that the allele came from mom
%                 gks.inheritance{end} = 'maternal';
%             elseif dad_carrier && ~isnan(mom_copy_number) && mom_copy_number==2 && ~mom_carrier
%                 %same but for dad
%                 gks.inheritance{end} = 'paternal';
%             elseif any(strcmpi(key.allele2, gks(existing,:).allele_name)) || strcmpi(key.allele2, key.allele1)
%                 % animal is homozygous, we will assign allele1 to mom
%                 % and allele2 to dad
%                 gks.inheritance{end} = 'paternal';
%             end
        end
        if ~isempty(gks)
            if gks.allele_id(end) > fetch1((sln_animal.Animal & struct('animal_id',animal_id)) * sln_animal.Species, 'ploidy') 
                error('Result conflicts with the existing genotype for this animal. If this is not a mistake, speak to an admin');
                
                % The new combination of alleles would exceed the maximum
                % number allowed for this locus.
                
                % Probably a mistake, but this could occur if e.g. a prior
                % genotyping result was erroneous. There are a few possible
                % scenarios:
                
                % (1) A prior genotyping result was entered by mistake.
                %  -> Delete the old GenotypeResult (this will also delete
                %  the Genotype)
                
                % (2) A prior genotyping result was entered correctly, but
                % we now believe it was a false positive/negative
                %  -> Delete the old Genotype, NOT the GenotypeResult
                
                % (3) This genotyping result was entered correctly, but we
                % believe the prior result is more accurate
                % -> Insert this GenotypeResult manually, ignore Genotype
                
                % WARNING: deleting data can have significant unintended
                % side effects. This should be done sparingly, and ideally
                % only for live animals.
            else
%                 if ~isempty(gks.inheritance{1})
%                     if strcmp(gks.inheritance{1}, gks.inheritance{2})
%                         error('Error inferring inheritance');
%                     elseif strcmp(gks.inheritance{1},'maternal')
%                         gks.inheritance{2} = 'paternal';
%                     else
%                         gks.inheritance{2} = 'maternal';
%                     end
%                 end
%                 if ~isempty(gks.inheritance{2})
%                     if strcmp(gks.inheritance{1}, gks.inheritance{2})
%                         error('Error inferring inheritance');
%                     elseif strcmp(gks.inheritance{2},'maternal')
%                         gks.inheritance{1} = 'paternal';
%                     else
%                         gks.inheritance{1} = 'maternal';
%                     end
%                 end
                gks(existing,:) = [];
                gks = table2struct(gks);
%                 [gks(strcmp({gks.inheritance},'')).inheritance] = deal(nan);
                if ~isempty(gks)
                    insert(sln_animal.Genotype, gks);
                end
            end
        end
    end
        
    text = sprintf('%s insert successful.\n%s', event_type, text);
    if nargin<3
        if C.inTransaction
            C.commitTransaction;
        end
        fprintf(text);
    end 
    inserted = true;
catch ME    
    fprintf('%s insert failed.\n', event_type);
    if nargin<3
        C.cancelTransaction;
    end
    inserted = false;
    text = ME.message;
    disp(text);
end
