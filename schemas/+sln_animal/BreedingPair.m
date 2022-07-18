%{
# A pair of animals for breeding
-> sln_animal.Source
---
(male_id) -> sln_animal.Animal
(female_id) -> sln_animal.Animal
%}

classdef BreedingPair < dj.Manual
    methods(Static)
        function q = active()
            %get latest ActiveateBreedingPair and DeactivateBreedingPair
            activate = sln_animal.BreedingPair * sln_animal.ActivateBreedingPair & 'LIMIT 1 PER source_id ORDER BY date DESC';
            deactivate = sln_animal.BreedingPair * sln_animal.DeactivateBreedingPair & 'LIMIT 1 PER source_id ORDER BY date DESC';

            q = activate - proj(deactivate);
        end
    end
end

