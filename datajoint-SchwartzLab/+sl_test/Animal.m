%{
# animal
animal_id: int unsigned auto_increment           # unique animal id
---
-> sl_test.Genotype                             # genotype of animal
is_tagged = 'F': enum('T','F')                  # true or false
tag_id = NULL : int unsigned                       # id number from our spreadsheets (how to check for duplicates here?)
species = 'Lab mouse' : varchar(64)             # species
dob = NULL : date                               # mouse date of birth
sex = 'Unknown' : enum('Male', 'Female', 'Unknown')          # sex of mouse - Male, Female, or Unknown/Unclassified
punch = 'none' : enum('L','R','Both','None')      # earpunch
animal_tags = NULL : longblob                   # struct with tags

unique index (tag_id)
%}

classdef Animal < dj.Manual
    
    methods(Static)
        function animals = living()
            q = sl_test.AnimalEventDeceased.living();

            animals = q.fetch('animal_id');
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end

        function [result, animals] = isLiving(animal_ids)
            q = sl_test.AnimalEventDeceased.living();
            q = restrict_by_animal_ids(q, animal_ids);
            
            animals = q.fetch('animal_id');
            result = ismember(animal_ids, [animals.animal_id]);
        end

        function animals = age(animal_ids, liveOnly)
            %returns age as a calendarDuration object
            
            if nargin>1 && liveOnly
                %restrict by living mice
                q = sl_test.AnimalEventDeceased.living();
            else 
                q = sl_test.Animal();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end
            
            animals = q.fetch('animal_id','dob');

            ages = num2cell(between(datetime({animals.dob}), date(),'weeks'));
            [animals(:).age] = ages{:};
            
            % one-liner:
            % [animals(:).ages] = subsref( num2cell(between(datetime({animals.dob}), date())), struct('type','{}', 'subs',':'))
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
        function animals = genotypeStatus(animal_ids, liveOnly)
            %get latest genotype status

            q = sl_test.AnimalEventGenotyped();

            if nargin>1 && liveOnly
                q = q & sl_test.AnimalEventDeceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id', 'genotype_status', 'LIMIT 1 PER animal_id');
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
        function [result, animals] = isGenotyped(animal_ids)
           animals = sl_test.Animal.genotypeStatus(animal_ids);
           result = ismember(animal_ids, [animals.animal_id]);
        end
        
        function animals = withEvent(eventType, animal_ids, liveOnly)
            %has this event

            if nargin>2 && liveOnly 
                q = sl_test.AnimalEventDeceased.living();
            else
                q = sl_test.Animal();
            end
            q = q & feval(sprintf('sl_test.AnimalEvent%s', eventType));

            if nargin>1 && ~isempty(animal_ids)
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id');
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end

        end
        
        function [result, animals] = hasEvent(eventType, animal_ids)
            animals = sl_test.Animal.withEvent(eventType, animal_ids);
            result = ismember(animal_ids, [animals.animal_id]);
        end
        
        function animals = cageNumber(animal_ids, liveOnly)

            q = sl_test.AnimalEventAssignCage.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sl_test.AnimalEventDeceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','cage_number');
            animals = rmfield(animals, 'event_id');
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
        function [result, animals] = isCaged(animal_ids)
            animals = sl_test.Animal.cageNumber(animal_ids);
            result = ismember(animal_ids, [animals.animal_id]);
        end
        
    end

end

function q = restrict_by_animal_ids(q, animal_ids)
    if ~isa(animal_ids,'cell')
        animal_ids = num2cell(animal_ids);
    end
    q = q & struct('animal_id', animal_ids);
end

