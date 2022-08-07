function [] = copy_animal_from_sl_animal(animal_id)
old_entry = sl.Animal & sprintf('animal_id=%d',animal_id);
if ~old_entry.exists
    error('Animal %d not found in sl.Animal', animal_id);
end

key = fetch(old_entry, '*');
key.species_name = 'mouse';
key.background_name = 'C57bl/6'; %as far as we know... not sure how the agouti mice were marked

do_entry = false;
switch key.source
    case 'vendor'
    
    case 'breeding'

    case 'other lab'

    otherwise %should be the easy cases
        %source is unknown
        key = rmfield(key,{'source_id'});
        do_entry = true;
end

if do_entry    
    fprintf('Inserting animal: %d\n', key.animal_id);
    if isempty(key.dob)
        key = rmfield(key,'dob');
    end
    key = rmfield(key,{'source', 'genotype_name', 'species'});
    insert(sln_animal.Animal,key);
    sln_animal.updateGenotypeString(key.animal_id);
else
    fprintf('Not inserting animal: %d', key.animal_id);
end



