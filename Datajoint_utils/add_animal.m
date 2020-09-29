function [] = add_animal(key, cage_key)
try
    %test for duplicate tag_id
    if isfield(key,'tag_id')
        matchingIDEntry = sl.Animal & ['tag_id=' num2str(key.tag_id)];
        if matchingIDEntry.exists
            errordlg(['Animal with tag_id: ' num2str(key.tag_id) ' already in database']);
            error('Duplicate entry');
        end
    end
    insert(sl.Animal, key);
    disp('Animal insert successful');
    id = max(fetchn(sl.Animal, 'animal_id')); %last animmal added
    cage_key.animal_id = id;
    cage_key.cause = 'assigned at database insert';
    add_animalEvent(cage_key, 'AssignCage'); %already a transaction here - so can't embed in a transaction like I would like to
    disp('Cage assigment successful');
catch ME
    disp('Animal insert failed');
    rethrow(ME)
end
