%{
# animals paired for breeding
-> sln_animal.AnimalEvent
---
(male_id) -> sl.Animal
(female_id) -> sl.Animal
-> sln_animal.Cage
%}
classdef PairBreeders < dj.Manual
    properties
        printStr = '%s %s: Breeder pair created with male %d and female %d in cage %d, room %s. User: %s. (%s)\n';
        printFields = {'date', 'time', 'male_id', 'female_id', 'cage_number', 'room_number', 'cause', 'user_name' ,'notes'};
    end
end