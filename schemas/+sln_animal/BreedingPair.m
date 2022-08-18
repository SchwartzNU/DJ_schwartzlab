%{
# A pair of animals for breeding
-> sln_animal.Source
---
-> sln_animal.Strain
(male_id) -> sln_animal.Animal
(female_id) -> sln_animal.Animal
%}

classdef BreedingPair < dj.Manual
    methods(Static)
        function q = active()
            %get latest ActiveateBreedingPair and DeactivateBreedingPair
            activate = sln_animal.BreedingPair * sln_animal.ActivateBreedingPair & 'LIMIT 1 PER source_id ORDER BY date DESC';
            deactivate = sln_animal.BreedingPair * sln_animal.DeactivateBreedingPair & 'LIMIT 1 PER source_id ORDER BY date DESC';
            deactivate_struct = rmfield(fetch(deactivate),'ev_id');

            q = activate - deactivate_struct;
        end

        function ids = active_animal_ids(sex)
            if nargin < 1
                sex = 'both';
            end
            q = sln_animal.BreedingPair.active();
            if ~q.exists
                ids = [];
                return;
            end
            male_ids = fetchn(q,'male_id');
            female_ids = fetchn(q,'female_id');
            if strcmp(sex,'male')
                ids = male_ids;
            elseif strcmp(sex,'female')
                ids = female_ids;
            else
                ids = [male_ids; female_ids];
            end
        end
    end
end

