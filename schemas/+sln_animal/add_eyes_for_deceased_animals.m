function [] = add_eyes_for_deceased_animals()
missing_eyes = sln_animal.AnimalEvent * sln_animal.Deceased - sln_animal.Eye & 'LIMIT 1 PER animal_id ORDER BY date DESC';
keys = fetch(missing_eyes,'animal_id');
keysL = rmfield(keys,'event_id');
keysR = keysL;

for i=1:length(keysL)
    keysL(i).side = 'Left';
    keysR(i).side = 'Right';
end

insert(sln_animal.Eye,keysL);
insert(sln_animal.Eye,keysR);
