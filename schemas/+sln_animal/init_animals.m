old_animals = fetch(sl.Animal,'dob','sex', 'source', 'source_id','genotype_name');
[old_animals.species_name] = deal('mouse');
[old_animals(cellfun(@isempty,{old_animals(:).dob})).dob] = deal(nan);

%background
[old_animals.background_name] = deal('C57bl/6'); %not always... how to find this info?

new_animals = rmfield(old_animals, {'source', 'source_id', 'genotype_name'});

%source
vendor_ind = strcmp({old_animals.source}, 'vendor');
unique({old_animals(vendor_ind).source_id})

other_lab_ind = strcmp({old_animals.source}, 'other lab');
unique({old_animals(other_lab_ind).source_id})
unique({old_animals(other_lab_ind).genotype_name})

%% collaborator sources
all_collab_lines = fetchn(sln_animal.CollaboratorStrain, 'strain_name');

other_lab_ind = find(strcmp({old_animals.source}, 'other lab'));
length(other_lab_ind)
for i=1:length(other_lab_ind)
    curInd = other_lab_ind(i);
    sln_animal.CollaboratorStrain
    curSourceID = old_animals(curInd).source_id
    curGenotype = old_animals(curInd).genotype_name

    id = input('Choose source ID: ');
    new_animals(curInd).source_id = id;
end

%% vendor sources
all_strain_numbers = fetchn(sln_animal.VendorStrain, 'catalog_number');

vendor_ind = find(strcmp({old_animals.source}, 'vendor'));
for i=1:length(vendor_ind)
    curInd = vendor_ind(i);
    curSourceID = old_animals(curInd).source_id;
    if ~isempty(curSourceID)
        for j=1:length(all_strain_numbers)
            if strfind(curSourceID, all_strain_numbers{j})
                id = fetch1(sln_animal.VendorStrain & sprintf('catalog_number=%s', all_strain_numbers{j}), 'source_id');
                new_animals(curInd).source_id = id;
                new_animals(curInd).external_id = sprintf('OLD_DJID:%d', old_animals(curInd).animal_id);
                break;
            end
        end
    end
end

%% fix NaN dob to [] and source_id to nan
for i=1:length(new_animals)
    if isnan(new_animals(i).dob)
        new_animals(i).dob = [];
    end
    if isempty(new_animals(i).source_id)
        new_animals(i).source_id = nan;
    end
end

%% insert, temporarily to get them in - needed for breeder sources
insert(sln_animal.Animal, new_animals);

%% breeder cage sources
breeding_ind = find(strcmp({old_animals.source}, 'breeding'));
all_breeding_cages = fetchn(sl.BreedingCage,'cage_number');
breeding_cage_member_err_ind = [];
not_breeding_cage_ind = [];
inactive_breeding_cage_ind = [];
active_breeding_cage_ind = [];
error_list = [];

for i=1:length(breeding_ind)
    i
    curInd = breeding_ind(i);
    curSourceID = old_animals(curInd).source_id;

    if ismember(curSourceID, all_breeding_cages)
        b = sl.BreedingCage & sprintf('cage_number="%s"', curSourceID);
        try
            key.male_id = fetchn(b.getHistoricalMember('Male'), 'animal_id');
            if isempty(key.male_id)
                error('breeding cage has no male id');
            elseif length(key.male_id) > 1
                %who's the daddy
                disp('whos the daddy');
                baby_dob = old_animals(curInd).dob;
                for d=1:length(key.male_id)
                    ev_date = fetch1(sl.AnimalEventAssignCage & ...
                        sprintf('cage_number="%s"', thisCage) & ...
                        sprintf('animal_id=%d', key.male_id(i)),'date');
                    if ev_date > baby_dob
                        not_dad = key.male_id(i);
                    end
                end
                key.male_id = setdiff(key.male_id,not_dad);
                if length(key.male_id) > 1
                    error('multiple possible dads');
                end
            end
            key.female_id = fetch1(b.getHistoricalMember('Female'), 'animal_id');
            id = sln_animal.add_source(key,'BreedingPair');
            active_breeding_cage_ind = [active_breeding_cage_ind, curInd];
            new_animals(curInd).source_id = id;
        catch ME
            disp('error finding breeding cage member');
            breeding_cage_member_err_ind = [breeding_cage_member_err_ind, curInd];
            error_list{i} = ME;
            new_animals(curInd).external_id = sprintf('OLD_genotype_name: %s', old_animals(curInd).genotype_name);
        end
    else
        not_breeding_cage_ind = [not_breeding_cage_ind, curInd];
        new_animals(curInd).external_id = sprintf('OLD_genotype_name: %s', old_animals(curInd).genotype_name);
    end
end

%% fix NaN dob to [] and source_id to nan
for i=1:length(new_animals)
    if isnan(new_animals(i).dob)
        new_animals(i).dob = [];
    end
    if isempty(new_animals(i).source_id)
        new_animals(i).source_id = nan;
    end
end

%% insert
%insert(sln_animal.Animal, new_animals, 'REPLACE');
%sln_animal.Animal().insert(new_animals);

for i=1:length(new_animals)
    i
    breeding_pair_struct = [];
    if strcmp(new_animals(i).sex,'Female')
        breeding_pair = sln_animal.BreedingPair & sprintf('female_id=%d',new_animals(i).animal_id);
    elseif strcmp(new_animals(i).sex,'Male')
        breeding_pair = sln_animal.BreedingPair & sprintf('male_id=%d',new_animals(i).animal_id);
    end
    if ~strcmp(new_animals(i).sex,'Unknown')
        breeding_pair_struct = fetch(breeding_pair, '*');
    end
    if ~isempty(breeding_pair_struct)
        delQuick(breeding_pair);
        insert(sln_animal.Animal, new_animals(i), 'REPLACE');
        sln_animal.add_source(breeding_pair_struct,'BreedingPair');
    end
end

%% add old animal events to new database
%% Deceased
deceased_events_struct = rmfield(fetch(sl.AnimalEventDeceased,'*'), 'event_id');
for i=1:length(deceased_events_struct)
    sln_animal.add_event(deceased_events_struct(i), 'Deceased', 'REPLACE');
end

%% Assign protocol
assign_protocol_events_struct = rmfield(fetch(sl.AnimalEventAssignProtocol  ,'*'), 'event_id');
for i=1:length(assign_protocol_events_struct)
    i
    sln_animal.add_event(assign_protocol_events_struct(i), 'AssignProtocol', 'REPLACE');
end

%% Brain injection
brain_inj_events_struct = rmfield(fetch(sl.AnimalEventBrainInjection  ,'*'), 'event_id');
N = length(brain_inj_events_struct)
for i=1:length(brain_inj_events_struct)
    i
    sln_animal.add_event(brain_inj_events_struct(i), 'BrainInjection', 'REPLACE');
end

%% Eye injection
eye_inj_events_struct = rmfield(fetch(sl.AnimalEventEyeInjection  ,'*'), 'event_id');
N = length(eye_inj_events_struct)
for i=1:N
    i
    sln_animal.add_event(eye_inj_events_struct(i), 'EyeInjection', 'REPLACE');
end

%% Social Behavior session
soc_beh_session_events_struct = fetch(sl.AnimalEventSocialBehaviorSession  ,'*');
N = length(soc_beh_session_events_struct)
for i=1:N
    i
    sln_animal.add_event(soc_beh_session_events_struct(i), 'SocialBehaviorSession', 'REPLACE');
end

%% Reserved for session
res_session_events_struct = rmfield(fetch(sl.AnimalEventReservedForSession  ,'*'), 'event_id');
N = length(res_session_events_struct)
for i=1:N
    i
    sln_animal.add_event(res_session_events_struct(i), 'ReservedForSession', 'REPLACE');
end

%% Tag
tag_events_struct = rmfield(fetch(sl.AnimalEventTag  ,'*'), 'event_id');
N = length(tag_events_struct)
for i=1:N
    i
    sln_animal.add_event(tag_events_struct(i), 'Tag', 'REPLACE');
end

%% Reserved for Project
res_project_events_struct = rmfield(fetch(sl.AnimalEventReservedForProject  ,'*'), 'event_id');
N = length(res_project_events_struct)
for i=1:N
    i
    sln_animal.add_event(res_project_events_struct(i), 'ReservedForProject', 'REPLACE');
end

%% Assign cage
assign_cage_events_struct = rmfield(fetch(sl.AnimalEventAssignCage  ,'*'), 'event_id');
N = length(assign_cage_events_struct)
for i=1:N
    i
    cage_int = str2double(assign_cage_events_struct(i).cage_number);
    if ~isnan(cage_int) %can't add the non-numeric cage numbers
        assign_cage_events_struct(i).cage_number = cage_int;
        sln_animal.add_event(assign_cage_events_struct(i), 'AssignCage', 'REPLACE');
    end
end

%% Start by setting active breeding cages by establishing if the mice are alive
% breeding_pairs_struct = fetch(sln_animal.BreedingPair, '*');
% N = length(breeding_pairs_struct)
% for i=1:N
%     curPair = breeding_pairs_struct(i);
%     if ismember(curPair.male_id,[sln_animal.Animal.living.animal_id]) && ...
%             ismember(curPair.female_id,[sln_animal.Animal.living.animal_id])
%         
%     end
% end

%% Pair breeders -> activate breeding pair
pair_breeders_events_struct = rmfield(fetch(sl.AnimalEventPairBreeders  ,'*'), ...
    {'event_id', 'cage_number', 'room_number', 'time'});
N = length(pair_breeders_events_struct)
for i=1:N
    i
    curEvent = pair_breeders_events_struct(i);
    thisPair = sln_animal.BreedingPair & sprintf('male_id=%d',curEvent.male_id) ...
        & sprintf('female_id=%d',curEvent.female_id);
    
    if thisPair.exists
        curEvent = rmfield(curEvent,{'male_id','female_id'});
        curEvent.source_id = fetch1(thisPair,'source_id');
        curEvent
        insert(sln_animal.ActivateBreedingPair,curEvent);
    end
end

%% Separate breeders -> deactivate breeding pair
separate_breeders_events_struct = rmfield(fetch(sl.AnimalEventSeparateBreeders  ,'*'), ...
    {'event_id', 'cage_number','new_cage_male','new_room_male', 'new_cage_female','new_room_female', 'time'});
N = length(separate_breeders_events_struct)
for i=1:N
    i
    curEvent = separate_breeders_events_struct(i);
    thisPair = sln_animal.BreedingPair & sprintf('male_id=%d',curEvent.male_id) ...
        & sprintf('female_id=%d',curEvent.female_id);
    
    if thisPair.exists
        curEvent = rmfield(curEvent,{'male_id','female_id'});
        curEvent.source_id = fetch1(thisPair,'source_id');
        curEvent
        insert(sln_animal.DeactivateBreedingPair,curEvent);
    end
end


%% Log births
birth_events_struct = rmfield(fetch(sl.AnimalEventGaveBirth  ,'*'), {'event_id','number_of_pups'});
N = length(birth_events_struct)
for i=1:N
    i
    cage = str2double(birth_events_struct(i).cage_number);
    if ~isnan(cage)
        thisCage = sln_animal.Cage & sprintf('cage_number=%d',cage) & 'is_breeding="T"';
        if thisCage.count == 1
            breeder_assign_events = sln_animal.AssignCage * sln_animal.AnimalEvent & sprintf('cage_number=%d',cage) & 'cause="set as breeder"';
            if breeder_assign_events.count == 2
                animals_in_cage = fetchn(breeder_assign_events, 'animal_id');
                sex = fetch1(sln_animal.Animal & sprintf('animal_id=%d', animals_in_cage(1)), 'sex');
                if strcmp(sex, 'Female')
                    female_id = animals_in_cage(1);
                    male_id = animals_in_cage(2);
                else
                    female_id = animals_in_cage(2);
                    male_id = animals_in_cage(1);
                end

                breeder_source_id = fetchn(sln_animal.BreedingPair ...
                    & sprintf('male_id=%d', male_id) & sprintf('female_id=%d', female_id), 'source_id');
                if isempty(breeder_source_id)
                    key_pair.male_id = male_id;
                    key_pair.female_id = female_id;
                    breeder_source_id = sln_animal.add_source(key_pair,'BreedingPair');
                end
                birth_events_struct(i).source_id = breeder_source_id;
                birth_events_struct(i).cage_number = cage;
                sln_animal.add_event(birth_events_struct(i), 'Birth');
            end
        end
    end
end

%% Log wean
wean_events_struct = rmfield(fetch(sl.AnimalEventGaveBirth  ,'*'), 'event_id');
N = length(wean_events_struct)
for i=1:N
    i
    cage = str2double(wean_events_struct(i).cage_number);
    if ~isnan(cage)
        thisCage = sln_animal.Cage & sprintf('cage_number=%d',cage) & 'is_breeding="T"';
        if thisCage.count == 1
            breeder_assign_events = sln_animal.AssignCage * sln_animal.AnimalEvent & sprintf('cage_number=%d',cage) & 'cause="set as breeder"';
            if breeder_assign_events.count == 2
                animals_in_cage = fetchn(breeder_assign_events, 'animal_id');
                sex = fetch1(sln_animal.Animal & sprintf('animal_id=%d', animals_in_cage(1)), 'sex');
                if strcmp(sex, 'Female')
                    female_id = animals_in_cage(1);
                    male_id = animals_in_cage(2);
                else
                    female_id = animals_in_cage(2);
                    male_id = animals_in_cage(1);
                end

                breeder_source_id = fetchn(sln_animal.BreedingPair ...
                    & sprintf('male_id=%d', male_id) & sprintf('female_id=%d', female_id), 'source_id');
                if isempty(breeder_source_id)
                    key_pair.male_id = male_id;
                    key_pair.female_id = female_id;
                    breeder_source_id = sln_animal.add_source(key_pair,'BreedingPair');
                end
                wean_events_struct(i).source_id = breeder_source_id;
                wean_events_struct(i).cage_number = cage;
                sln_animal.add_event(wean_events_struct(i), 'Weaned');
            end
        end
    end
end

%% now genotypes
non_wt_ind = find(~strcmp({old_animals.genotype_name}, 'WT'));
unique({old_animals(non_wt_ind).genotype_name})

inferred_genotype_ind = [];
genotype_results_ind = [];
multi_allele_cases = [];
single_allele_cases = [];
no_genotype_cases = [];

length(non_wt_ind)
for i=1:length(non_wt_ind)
    i
    curInd = non_wt_ind(i)
    animal_id = old_animals(curInd).animal_id;
    %skip the done ones
    new_genotype_result_event = sln_animal.AnimalEvent * sln_animal.GenotypeResult & sprintf('animal_id=%d', animal_id);
    if ~new_genotype_result_event.exists
        genotype_events = sl.AnimalEventGenotyped & sprintf('animal_id=%d', animal_id);
        key = struct;
        if ~genotype_events.exists %first genotypes with no associated AnimalEventGenotyped events
            inferred_genotype_ind = [inferred_genotype_ind, curInd];
            curGenotype = old_animals(curInd).genotype_name;
            key.animal_id = animal_id;
            key.source_name = 'unknown';
            key.user_name = 'Unknown';
            key.date = fetch1(sln_animal.Animal & sprintf('animal_id=%d',animal_id), 'dob');
            key.time = '09:00:00';
            key.notes = 'inferred genotype from sl database - no genotyped event';
            key.locus_name = 'unknown';
            switch curGenotype
                case 'Ai14'
                    key.locus_name = 'ROSA';
                    key.allele1 = 'Ai14';
                case {'VGluT2-Cre', 'Vglut2-Cre mixed', 'Vglut-Cre C57', 'Vglut-C57bg', 'Vglut2-Cre mixed bg'}
                    key.locus_name = 'Slc17a6';
                    key.allele1 = 'VGluT2-Cre';
                case {'nNos creER', 'nNOS'}
                    key.locus_name = 'Nos1';
                    key.allele1 = 'nNOS-CreER';
                case 'Cspg4'
                    key.locus_name = 'Ifi208';
                    key.allele1 = 'Cspg4-Cre';
                case {'Gcamp6f', 'Gcamp'}
                    key.locus_name = 'ROSA';
                    key.allele1 = 'GCaMP6f';
                case {'Salsa6f', 'Salsa'}
                    key.locus_name = 'ROSA';
                    key.allele1 = 'Salsa6f';
                case 'CCK'
                    key.locus_name = 'Cck';
                    key.allele1 = 'CCK-Cre';
                case 'PDGFR beta ER'
                    key.locus_name = 'PDGFRb';
                    key.allele1 = 'PDGFR-Cre';
                case {'Opn5', 'opn5cre'}
                    key.locus_name = 'unknown';
                    key.allele1 = 'Opn5-Cre';
                case 'Gad2cre'
                    key.locus_name = 'Gad2';
                    key.allele1 = 'Gad2-Cre';
                case {'TITL iGluSnfr', 'iGluSnfr'}
                    key.locus_name = 'TIGRE';
                    key.allele1 = 'Ai87';
                case 'RIK'
                    key.locus_name = 'unknown';
                    key.allele1 = 'RIK';
                case 'Scg2'
                    key.locus_name = 'unknown';
                    key.allele1 = 'Scg2-tTA';
                case 'Tusc5'
                    key.locus_name = 'Trarg1';
                    key.allele1 = 'Tusc5-eGFP';
                case 'Prss56'
                    key.locus_name = 'Prss56';
                    key.allele1 = 'Prss56-KO';
                case 'Prss56_over'
                    key.locus_name = 'Prss56';
                    key.allele1 = 'Prss56-Over';
                case 'Grm6'
                    key.locus_name = 'Grm6';
                    key.allele1 = 'Grm6-Cre';
            end
            key
            inserted = sln_animal.add_event(key, 'GenotypeResult');
            if ~inserted
                disp('no genotyped event');
                curGenotype
                key.locus_name = 'unknown';
                key.allele1 = 'Ambiguous';
                sln_animal.add_event(key, 'GenotypeResult');
                %pause;
            end
        else
            genotype_results_ind = [genotype_results_ind, curInd];
            N_genotype_events = genotype_events.count;
            curGenotype = old_animals(curInd).genotype_name;
            if N_genotype_events==1
                genotype_status = fetch1(genotype_events,'genotype_status')
                genotype_status = genotype_status{1};
                if contains(genotype_status, '/')
                    multi_allele_cases = [multi_allele_cases, curInd];
                    genotype_status_parts = split(genotype_status, {'/', 'x'});
                    genotype_parts = split(curGenotype, {'/', 'x'});
                    Nparts = length(genotype_status_parts);
                    Nparts_g = length(genotype_parts);
                    if Nparts == Nparts_g
                        for n=1:Nparts
                            cur_status = strtrim(genotype_status_parts{n});
                            cur_genotype = strtrim(genotype_parts{n});
                            key = rmfield(fetch(genotype_events,'*'), {'event_id', 'genotype_status'});
                            key.source_name = 'unknown';
                            switch cur_genotype %TODO: add chat
                                case 'Ai14'
                                    key.locus_name = 'ROSA';
                                    trans.allele_name = 'Ai14';
                                case {'VGluT2-Cre', 'Vglut2-Cre mixed', 'Vglut-Cre C57', 'Vglut-C57bg', 'Vglut2-Cre mixed bg'}
                                    key.locus_name = 'Slc17a6';
                                    trans.allele_name = 'VGluT2-Cre';
                                case {'nNos creER', 'nNOS'}
                                    key.locus_name = 'Nos1';
                                    trans.allele_name = 'nNOS-CreER';
                                case 'Cspg4'
                                    key.locus_name = 'Ifi208';
                                    trans.allele_name = 'Cspg4-Cre';
                                case {'Gcamp6f', 'Gcamp'}
                                    key.locus_name = 'ROSA';
                                    trans.allele_name = 'GCaMP6f';
                                case {'Salsa6f', 'Salsa'}
                                    key.locus_name = 'ROSA';
                                    key.allele1 = 'Salsa6f';
                                case 'CCK'
                                    key.locus_name = 'Cck';
                                    trans.allele_name = 'CCK-Cre';
                                case 'PDGFR beta ER'
                                    key.locus_name = 'PDGFRb';
                                    trans.allele_name = 'PDGFR-Cre';
                                case {'Opn5', 'opn5cre'}
                                    key.locus_name = 'unknown';
                                    trans.allele_name = 'Opn5-Cre';
                                case 'Gad2cre'
                                    key.locus_name = 'Gad2';
                                    trans.allele_name = 'Gad2-Cre';
                                case {'TITL iGluSnfr', 'iGluSnfr'}
                                    key.locus_name = 'TIGRE';
                                    trans.allele_name = 'Ai87';
                                case 'RIK'
                                    key.locus_name = 'unknown';
                                    trans.allele_name = 'RIK';
                                case 'Scg2'
                                    key.locus_name = 'unknown';
                                    trans.allele_name = 'Scg2-tTA';
                                case 'Tusc5'
                                    key.locus_name = 'Trarg1';
                                    trans.allele_name = 'Tusc5-eGFP';
                                case 'Prss56'
                                    key.locus_name = 'Prss56';
                                    trans.allele_name = 'Prss56-KO';
                                case 'Prss56_over'
                                    key.locus_name = 'Prss56';
                                    trans.allele_name = 'Prss56-Over';
                                case 'Grm6'
                                    key.locus_name = 'Grm6';
                                    trans.allele_name = 'Grm6-Cre';
                            end
                            switch cur_status
                                case 'non-carrier'
                                    key.allele1 = 'WT';
                                    key.allele2 = 'WT';
                                case 'het'
                                    key.allele1 = trans.allele_name;
                                    key.allele2 = 'WT';
                                case 'carrier'
                                    key.allele1 = trans.allele_name;
                                case 'homo'
                                    key.allele1 = trans.allele_name;
                                    key.allele2 = trans.allele_name;
                            end
                            if isfield(key,'allele1')
                                key
                                dob = fetch1(sln_animal.Animal & sprintf('animal_id=%d',animal_id), 'dob');
                                if datetime(dob) > datetime(key.date) %fix erroneously entered dates of genotyped events
                                    key.date = string(dob + days(28),'yyyy-MM-dd') %28 days after birth fixed date
                                end
                                inserted = sln_animal.add_event(key, 'GenotypeResult');
                                if ~inserted
                                    cur_status
                                    key.locus_name = 'unknown';
                                    key.allele1 = 'Ambiguous';
                                    sln_animal.add_event(key, 'GenotypeResult');
                                    %pause;
                                end
                            end
                        end
                    end

                elseif isempty(genotype_status)
                    no_genotype_cases = [no_genotype_cases, curInd];
                else
                    key = rmfield(fetch(genotype_events,'*'), {'event_id', 'genotype_status'});
                    key.source_name = 'unknown';
                    single_allele_cases = [single_allele_cases, curInd];
                    switch curGenotype
                        case 'Ai14'
                            key.locus_name = 'ROSA';
                            trans.allele_name = 'Ai14';
                        case {'VGluT2-Cre', 'Vglut2-Cre mixed', 'Vglut-Cre C57', 'Vglut-C57bg', 'Vglut2-Cre mixed bg'}
                            key.locus_name = 'Slc17a6';
                            trans.allele_name = 'VGluT2-Cre';
                        case {'nNos creER', 'nNOS'}
                            key.locus_name = 'Nos1';
                            trans.allele_name = 'nNOS-CreER';
                        case 'Cspg4'
                            key.locus_name = 'Ifi208';
                            trans.allele_name = 'Cspg4-Cre';
                        case {'Gcamp6f', 'Gcamp'}
                            key.locus_name = 'ROSA';
                            trans.allele_name = 'GCaMP6f';
                        case {'Salsa6f', 'Salsa'}
                            key.locus_name = 'ROSA';
                            key.allele1 = 'Salsa6f';
                        case 'CCK'
                            key.locus_name = 'Cck';
                            trans.allele_name = 'CCK-Cre';
                        case 'PDGFR beta ER'
                            key.locus_name = 'PDGFRb';
                            trans.allele_name = 'PDGFR-Cre';
                        case {'Opn5', 'opn5cre'}
                            key.locus_name = 'unknown';
                            trans.allele_name = 'Opn5-Cre';
                        case 'Gad2cre'
                            key.locus_name = 'Gad2';
                            trans.allele_name = 'Gad2-Cre';
                        case {'TITL iGluSnfr', 'iGluSnfr'}
                            key.locus_name = 'TIGRE';
                            trans.allele_name = 'Ai87';
                        case 'RIK'
                            key.locus_name = 'unknown';
                            trans.allele_name = 'RIK';
                        case 'Scg2'
                            key.locus_name = 'unknown';
                            trans.allele_name = 'Scg2-tTA';
                        case 'Tusc5'
                            key.locus_name = 'Trarg1';
                            trans.allele_name = 'Tusc5-eGFP';
                        case 'Prss56'
                            key.locus_name = 'Prss56';
                            trans.allele_name = 'Prss56-KO';
                        case 'Prss56_over'
                            key.locus_name = 'Prss56';
                            trans.allele_name = 'Prss56-Over';
                        case 'Grm6'
                            key.locus_name = 'Grm6';
                            trans.allele_name = 'Grm6-Cre';
                    end
                    switch genotype_status
                        case 'non-carrier'
                            key.allele1 = 'WT';
                            key.allele2 = 'WT';
                        case 'het'
                            key.allele1 = trans.allele_name;
                            key.allele2 = 'WT';
                        case 'carrier'
                            key.allele1 = trans.allele_name;
                        case 'homo'
                            key.allele1 = trans.allele_name;
                            key.allele2 = trans.allele_name;
                    end
                    if isfield(key,'allele1')
                        key
                        dob = fetch1(sln_animal.Animal & sprintf('animal_id=%d',animal_id), 'dob');
                        if datetime(dob) > datetime(key.date) %fix erroneously entered dates of genotyped events
                            key.date = string(datetime(dob) + days(28),'yyyy-MM-dd') %28 days after birth fixed date
                        end
                        inserted = sln_animal.add_event(key, 'GenotypeResult');
                        if ~inserted
                            key.locus_name = 'unknown';
                            key.allele1 = 'Ambiguous';
                            sln_animal.add_event(key, 'GenotypeResult');
                            %pause;
                        end
                    end
                end
            else %multiple genotyped events
                multi_allele_cases = [multi_allele_cases, curInd];
                genotype_events_struct = fetch(genotype_events,'*');
                for g=1:length(genotype_events_struct)
                    genotype_ev = genotype_events_struct(g);
                    genotype_status_cur = genotype_ev.genotype_status;

                    genotype_status_parts = split(genotype_status_cur, {'/', 'x'});
                    genotype_parts = split(curGenotype, {'/', 'x'});
                    Nparts = length(genotype_status_parts);
                    Nparts_g = length(genotype_parts);
                    if Nparts == Nparts_g
                        for n=1:Nparts
                            cur_status = strtrim(genotype_status_parts{n});
                            cur_genotype = strtrim(genotype_parts{n});
                            key = rmfield(genotype_ev, {'event_id', 'genotype_status'});
                            key.source_name = 'unknown';
                            switch cur_genotype
                                case 'Ai14'
                                    key.locus_name = 'ROSA';
                                    trans.allele_name = 'Ai14';
                                case {'Vglut2-Cre mixed', 'Vglut-Cre C57', 'Vglut-C57bg', 'Vglut2-Cre mixed bg'}
                                    key.locus_name = 'Slc17a6';
                                    trans.allele_name = 'VGluT2-Cre';
                                case {'nNos creER', 'nNOS'}
                                    key.locus_name = 'Nos1';
                                    trans.allele_name = 'nNOS-CreER';
                                case 'Cspg4'
                                    key.locus_name = 'Ifi208';
                                    trans.allele_name = 'Cspg4-Cre';
                                case {'Gcamp6f', 'Gcamp'}
                                    key.locus_name = 'ROSA';
                                    trans.allele_name = 'GCaMP6f';
                                case {'Salsa6f', 'Salsa'}
                                    key.locus_name = 'ROSA';
                                    key.allele1 = 'Salsa6f';
                                case 'CCK'
                                    key.locus_name = 'Cck';
                                    trans.allele_name = 'CCK-Cre';
                                case 'PDGFR beta ER'
                                    key.locus_name = 'PDGFRb';
                                    trans.allele_name = 'PDGFR-Cre';
                                case {'Opn5', 'opn5cre'}
                                    key.locus_name = 'unknown';
                                    trans.allele_name = 'Opn5-Cre';
                                case 'Gad2cre'
                                    key.locus_name = 'Gad2';
                                    trans.allele_name = 'Gad2-Cre';
                                case {'TITL iGluSnfr', 'iGluSnfr'}
                                    key.locus_name = 'TIGRE';
                                    trans.allele_name = 'Ai87';
                                case 'RIK'
                                    key.locus_name = 'unknown';
                                    trans.allele_name = 'RIK';
                                case 'Scg2'
                                    key.locus_name = 'unknown';
                                    trans.allele_name = 'Scg2-tTA';
                                case 'Tusc5'
                                    key.locus_name = 'Trarg1';
                                    trans.allele_name = 'Tusc5-eGFP';
                                case 'Prss56'
                                    key.locus_name = 'Prss56';
                                    trans.allele_name = 'Prss56-KO';
                                case 'Prss56_over'
                                    key.locus_name = 'Prss56';
                                    trans.allele_name = 'Prss56-Over';
                                case 'Grm6'
                                    key.locus_name = 'Grm6';
                                    trans.allele_name = 'Grm6-Cre';
                            end
                            switch cur_status
                                case 'non-carrier'
                                    key.allele1 = 'WT';
                                    key.allele2 = 'WT';
                                case 'het'
                                    key.allele1 = trans.allele_name;
                                    key.allele2 = 'WT';
                                case 'carrier'
                                    key.allele1 = trans.allele_name;
                                case 'homo'
                                    key.allele1 = trans.allele_name;
                                    key.allele2 = trans.allele_name;
                            end
                            if isfield(key,'allele1')
                                key
                                dob = fetch1(sln_animal.Animal & sprintf('animal_id=%d',animal_id), 'dob');
                                if datetime(dob) > datetime(key.date) %fix erroneously entered dates of genotyped events
                                    key.date = string(dob + days(28),'yyyy-MM-dd') %28 days after birth fixed date
                                end
                                inserted = sln_animal.add_event(key, 'GenotypeResult');
                                if ~inserted
                                    key.locus_name = 'unknown';
                                    key.allele1 = 'Ambiguous';
                                    sln_animal.add_event(key, 'GenotypeResult');
                                    cur_status
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end




