function [] = add_animal(key, cage_key)
C = dj.conn;
C.startTransaction;
try

    insert(sl.Animal, key);
    
    % id = max(fetchn(sl.Animal, 'animal_id')); %last animmal added
    id = C.query('SELECT max(animal_id) as last FROM sl.animal').last; %this is guaranteed by datajoint, less data transfer than above
    %there is a potential issue here if two people are inserting animals at the same time
    %at the moment we're just assuming that won't happen
    %but maybe we can limit the number of simultaneous transactions?

    cage_key.animal_id = id;
    cage_key.cause = 'assigned at database insert';
    text = add_animalEvent(cage_key, 'AssignCage', C);
    % disp('Cage assigment successful');
    C.commitTransaction;
    fprintf('Animal insert successful.\n%s', text);

catch ME
    if contains(ME.message, 'Duplicate entry') && contains(ME.message,'tag_id')
        disp('Animal with that tag ID already exists in database!');
    else
        % disp('Unknown error occurred while inserting animal.');
    end
    disp('Animal insert failed');
    C.cancelTransaction;
    rethrow(ME)
end
