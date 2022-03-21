old_animals = fetch(sl.Animal,'dob','sex');
[old_animals.species_name] = deal('mouse');
[old_animals(cellfun(@isempty,{old_animals(:).dob})).dob] = deal(nan);
% [old_animals(:).source_id] = deal(1); %TODO: this is a placeholder!!
% old_animals.background_name = 'C57bl/6';
sln_animal.Animal().insert(old_animals);