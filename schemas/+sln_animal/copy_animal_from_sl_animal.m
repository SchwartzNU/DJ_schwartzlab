function [] = copy_animal_from_sl_animal(animal_id)
old_entry = sl.Animal & sprintf('animal_id=%d',animal_id);
if ~old_entry.exists
    error('Animal %d not found in sl.Animal', animal_id);
end

key = fetch(old_entry, '*');
key.species_name = 'mouse'
key.background_name = 'C57bl/6';
sln_animal.Source
sln_animal.Source * sln_animal.CollaboratorStrain
key.source_id = 5;
key.external_id = 'Fawzi tag: 1987';
key = rmfield(key,{'source', 'genotype_name', 'species'})
%keyboard;
insert(sln_animal.Animal,key);
