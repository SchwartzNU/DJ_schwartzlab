function [inserted, txt] = add_animal(key, tag_key, cage_key, protocol_key)
C = dj.conn;
C.startTransaction;
inserted = false;
txt = '';
try
    insert(sl.Animal, key);
    
    id = max(fetchn(sl.Animal, 'animal_id')); %last animmal added
    %id = C.query('SELECT max(animal_id) as last FROM sl.animal').last; %this is guaranteed by datajoint, less data transfer than above
    %there is a potential issue here if two people are inserting animals at the same time
    %at the moment we're just assuming that won't happen
    %but maybe we can limit the number of simultaneous transactions?

    %there is no way around this being 2 transactions unfortunately
    %because the event has a foreign key to the animal
    
    %check for birthdate in the future and throw error
    if isfield(key,'dob') && ~isempty(key.dob) && ...
            datetime(key.dob) > datetime('today')
        disp('Birth date cannot be in the future')
        error('Birth date cannot be in the future');        
    end
    
    %add tag assignment event
    tag_key.animal_id = id;
    text = add_animalEvent(tag_key, 'Tag',C);
    
    %add cage assignment event
    if isempty(cage_key.cage_number)
        error('Animals inserted using GUI must be assigned a cage number for QA purposes.');
    end
    cage_key.animal_id = id;
    cage_key.cause = 'assigned at database insert';
    add_animalEvent(cage_key, 'AssignCage',C);
    %disp('Cage assigment successful');
    
    %add protocol assignment event
    if ~isempty(protocol_key) && ~strcmp(protocol_key.protocol_name,'Unknown')
        protocol_key.animal_id = id;
        add_animalEvent(protocol_key, 'AssignProtocol',C);
        %disp('Protocol assigment successful');
    end
    
    fprintf('Animal insert successful.\n%s', text);
    C.commitTransaction;
    txt = 'Animal insert successful.';
    inserted = true;
catch ME
    if contains(ME.message, 'Duplicate entry') && contains(ME.message,'tag_id')
        disp('Animal with that tag ID already exists in database!');
        txt = 'Animal with that tag ID already exists in database!';
    else
        disp(ME.message);
        txt = ME.message;
    end
    disp('Animal insert failed');
    C.cancelTransaction;
    inserted = false;
    %rethrow(ME)
end
