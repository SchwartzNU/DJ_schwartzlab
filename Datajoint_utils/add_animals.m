function [inserted, txt] = add_animals(keyVec, cage_keyVec, protocol_keyVec)
C = dj.conn;
C.startTransaction;
inserted = false;
txt = '';
N_animals = length(keyVec);
try
    %prev_id = max(fetchn(sl.Animal, 'animal_id')); %last animal added
    for i=1:N_animals
        i
        key = keyVec(i)
        cage_key = cage_keyVec(i)
        protocol_key = protocol_keyVec(i)
        insert(sl.Animal, key);
        
        %id = prev_id + i
        id = max(fetchn(sl.Animal, 'animal_id')); %last animal added
        %id = C.query('SELECT max(animal_id) as last FROM sl.animal').last; %this is guaranteed by datajoint, less data transfer than above
        %there is a potential issue here if two people are inserting animals at the same time
        %at the moment we're just assuming that won't happen
        %but maybe we can limit the number of simultaneous transactions?
        
        %there is no way around this being 2 transactions unfortunately
        %because the event has a foreign key to the animal
        cage_key.animal_id = id;
        cage_key.cause = 'assigned at database insert';
        text = add_animalEvent(cage_key, 'AssignCage',C);
        disp('Cage assigment successful');
        
        %add protocol assignment event
        protocol_key.animal_id = id;
        add_animalEvent(protocol_key, 'AssignProtocol',C);
        disp('Protocol assigment successful');
        
        fprintf('Animal insert successful.\n%s', text);
    end
    C.commitTransaction;
    txt = 'Animal insert successful.';
    inserted = true;
catch ME
    if contains(ME.message, 'Duplicate entry') && contains(ME.message,'tag_id')
        disp('Animal with that tag ID already exists in database!');
        txt = 'Animal with that tag ID already exists in database!';
    else
        disp('Unknown error occurred while inserting animal.');
        txt = 'Unknown error occurred while inserting animal.';
    end
    disp('Animal insert failed');
    C.cancelTransaction;
    inserted = false;
    %rethrow(ME)
end
