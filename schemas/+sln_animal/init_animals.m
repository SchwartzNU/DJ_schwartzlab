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

%% breeder cage sources
breeding_ind = find(strcmp({old_animals.source}, 'breeding'));
all_breeding_cages = fetchn(sl.BreedingCage,'cage_number');
breeding_cage_member_err_ind = [];
not_breeding_cage_ind = [];
inactive_breeding_cage_ind = [];
active_breeding_cage_ind = [];

for i=1:length(breeding_ind)
    i
    curInd = breeding_ind(i);
    curSourceID = old_animals(curInd).source_id;
    
    if ismember(curSourceID, all_breeding_cages)
        b = sl.BreedingCage & sprintf('cage_number="%s"', curSourceID)
        b.getMember('Male')        
        pause;
        try

            key.male_id = fetch1(b.getMember('Male'), 'animal_id')
            key.female_id = fetch1(b.getMember('Female'), 'animal_id')
            id = sln_animal.add_source(key,'BreedingPair');
            active_breeding_cage_ind = [active_breeding_cage_ind, curInd];
            new_animals(curInd).source_id = id;
        catch
            disp('error finding breeding cage member');
            breeding_cage_member_err_ind = [breeding_cage_member_err_ind, curInd];
            new_animals(curInd).external_id = sprintf('OLD_genotype_name: %s', old_animals(curInd).genotype_name);
        end
    else
        not_breeding_cage_ind = [not_breeding_cage_ind, curInd];
        new_animals(curInd).external_id = sprintf('OLD_genotype_name: %s', old_animals(curInd).genotype_name);
    end
end

%% insert
sln_animal.Animal().insert(new_animals);

%% now genotypes
non_wt_ind = find(~strcmp({old_animals.genotype_name}, 'WT'));
unique({old_animals(non_wt_ind).genotype_name})

inferred_genotype_ind = [];
genotype_results_ind = [];
multi_allele_cases = [];
single_allele_cases = [];

for i=1:length(non_wt_ind)
    curInd = non_wt_ind(i);
    animal_id = old_animals(curInd).animal_id;
    genotype_events = sl.AnimalEventGenotyped & sprintf('animal_id=%d', animal_id);
    key = struct;
    if ~genotype_events.exists %first genotypes with no associated AnimalEventGenotyped events
        inferred_genotype_ind = [inferred_genotype_ind, curInd];
        curGenotype = old_animals(curInd).genotype_name;
        key.animal_id = animal_id;
      
        switch curGenotype
            case 'Ai14'
                key.locus_name = 'ROSA';
                key.allele_name = 'Ai14';
            case 'Vglut2-Cre mixed bg'
                key.locus_name = 'Slc17a6';
                key.allele_name = 'VGluT2-Cre';
            case 'nNos creER'
                key.locus_name = 'Nos1';
                key.allele_name = 'nNOS-CreER';
            case 'Cspg4'
                key.locus_name = 'Ifi208';
                key.allele_name = 'Cspg4-Cre';
            case 'Gcamp6f'
                key.locus_name = 'ROSA';
                key.allele_name = 'GCaMP6f';
            case 'CCK'
                key.locus_name = 'CCK';
                key.allele_name = 'CCK-Cre';
            case 'Opn5'
                key.locus_name = 'unknown';
                key.allele_name = 'Opn5-Cre';
        end
        key.allele_id = 1;
        %insert(sln_animal.Genotype,key);
    else
        genotype_results_ind = [genotype_results_ind, curInd];
        N_genotype_events = genotype_events.count;
        if N_genotype_events==1
            genotype_status = fetch1(genotype_events,'genotype_status');
            if contains(genotype_status, '/')
                multi_allele_cases = [multi_allele_cases, curInd];
            else
                key = struct;
                key.animal_id = animal_id;
                single_allele_cases = [single_allele_cases, curInd];
                switch genotype_status
                    case 'non-carrier'
                        a1 = 'WT';
                        a2 = 'WT';
                    case 'het'
                        a1 = 'trans';
                        a2 = 'WT';
                    case 'carrier'
                        a1 = 'trans';
                        a2 = '?';
                    case 'homo'
                        a1 = 'trans';
                        a2 = 'trans';
                    case 'unknown'
                        a1 = '?';
                        a2 = '?';
                end
                WT.allele_name = 'WT';
                switch curGenotype
                    case 'Ai14'
                        trans.locus_name = 'ROSA';
                        trans.allele_name = 'Ai14';
                    case {'Vglut2-Cre mixed bg', 'Vglut-C57bg/WT', 'Vglut-Cre C57/BLK6 bg'}
                        trans.locus_name = 'Slc17a6';
                        trans.allele_name = 'VGluT2-Cre';
                    case 'nNos creER'
                        key.locus_name = 'Nos1';
                        key.allele_name = 'nNOS-CreER';
                    case 'Cspg4'
                        key.locus_name = 'Ifi208';
                        key.allele_name = 'Cspg4-Cre';
                    case 'Gcamp6f'
                        trans.locus_name = 'ROSA';
                        trans.allele_name = 'GCaMP6f';
                    case 'Salsa6f'
                        trans.locus_name = 'ROSA';
                        trans.allele_name = 'Salsa6f';
                    case {'CCK', 'CCK/WT'}
                        trans.locus_name = 'CCK';
                        trans.allele_name = 'CCK-Cre';
                    case 'opn5cre/WT'
                        trans.locus_name = 'unknown';
                        trans.allele_name = 'Opn5-Cre';
                    case 'ChAT'
                        key.locus_name = 'CHAT';
                        key.allele_name = 'ChAT-Cre';
                    case 'TITL iGluSnfr'
                        key.locus_name = 'TIGRE';
                        key.allele_name = 'Ai87';
                    case 'Tusc5'
                        key.locus_name = 'Trarg1';
                        key.allele_name = 'Tusc5-eGFP';
                end
                WT.locus_name = trans.locus_name;

            end
        else
            multi_allele_cases = [multi_allele_cases, curInd];
        end
    end
end




