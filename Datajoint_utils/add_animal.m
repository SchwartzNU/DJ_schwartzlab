function [] = add_animal(key, isAlive, isGenotyped, isInjected, isForBehavior)
C = dj.conn;
C.startTransaction
try    
    %test for duplicate tag_id
    if isfield(key,'tag_id')
       matchingIDEntry = sl_test.Animal & ['tag_id=' num2str(key.tag_id)];
       if matchingIDEntry.exists
           errordlg(['Animal with tag_id: ' num2str(key.tag_id) ' already in database']);
           error('Duplicate entry');
       end
    end
    key.animal_id = max(fetchn(sl_test.Animal, 'animal_id')) + 1; 
    key_animal = key;
    if isfield(key_animal, 'cage_number')
        key_animal = rmfield(key_animal, 'cage_number');
        key_animal.initial_cage_number = key.cage_number;
    end
    if isfield(key_animal, 'genotype_status')
        key_animal = rmfield(key_animal, 'genotype_status');
    end        
    insert(sl_test.Animal, key_animal);
        
    if isAlive
        key_live.animal_id = key.animal_id;
        key_live.cage_number = key.cage_number;
        insert(sl_test.AnimalLive, key_live);
    end
    
    if isGenotyped
        key_g.animal_id = key.animal_id;
        key_g.genotype_status = key.genotype_status;
        insert(sl_test.AnimalGenotyped, key_g);
    end
    
    if isInjected
        key_inj.animal_id = key.animal_id;
        insert(sl_test.AnimalForExperimentalInjection, key_inj);
    end
    
    if isForBehavior
        key_b.animal_id = key.animal_id;
        insert(sl_test.AnimalForBehavior, key_b);
    end
    
    disp('Insert successful');
    C.commitTransaction;    
catch
    errordlg('Insert failed');
    C.cancelTransaction;
end