%{
# animal
animal_id: int unsigned auto_increment           # unique animal id
---
-> sl_test.Genotype                             # genotype of animal
is_tagged = 'F': enum('T','F')                  # true or false
tag_id = 0 : int unsigned                       # id number from our spreadsheets (how to check for duplicates here?)
species = 'Lab mouse' : varchar(64)             # species
dob = NULL : date                               # mouse date of birth
sex = 'Unknown' : enum('Male', 'Female', 'Unknown')          # sex of mouse - Male, Female, or Unknown/Unclassified
punch = 'none' : enum('L','R','Both','None')      # earpunch
animal_tags = NULL : longblob                   # struct with tags
%}

classdef Animal < dj.Manual
    
    methods(Static)
        function animals = living()
            q = sl_test.AnimalEventDeceased.living();

            animals = q.fetch('animal_id');
        end

        function result = isLiving(animal_ids)
            q = sl_test.AnimalEventDeceased.living();
            q = restrict_by_animal_ids(q, animal_ids);
            
            result = q.fetch('animal_id');
            result = ismember(animal_ids, [result(:).animal_id]);
        end

        function animals = age(liveOnly, animal_ids)
            %returns age as a calendarDuration object
            
            if nargin && liveOnly
                %restrict by living mice
                q = sl_test.AnimalEventDeceased.living();
            else 
                q = sl_test.Animal();
            end

            if nargin>1
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end
            
            animals = q.fetch('animal_id','dob');

            ages = num2cell(between(datetime({animals.dob}), date(),'weeks'));
            [animals(:).ages] = ages{:};
            
            % one-liner:
            % [animals(:).ages] = subsref( num2cell(between(datetime({animals.dob}), date())), struct('type','{}', 'subs',':'))
            
        end
        
        function animals = genotype_status(liveOnly, animal_ids)
            %get latest genotype status

            q = sl_test.AnimalEventGenotyped();

            if nargin && liveOnly
                q = q & sl_test.AnimalEventDeceased.living();
            end

            if nargin>1
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id', 'genotype_status', 'LIMIT 1 PER animal_id');

        end
        
        % function ind_struct = hasEvent(eventType, liveOnly)
        %     %has this event
        %     if nargin<2
        %         liveOnly = false;
        %     end
        %     if liveOnly
        %        animals = fetchn(sl.Animal - sl.AnimalEventDeceased, 'animal_id');
        %        animals_withEvent = fetchn((sl.Animal - sl.AnimalEventDeceased) & eval(['sl.AnimalEvent' eventType]), 'animal_id');
        %     else
        %        animals = fetchn(sl.Animal, 'animal_id');
        %        animals_withEvent = fetchn(sl.Animal & eval(['sl.AnimalEvent' eventType]), 'animal_id');
        %     end
        %     ind = ismember(animals,animals_withEvent);
        %     field_name = ['hasEvent_' eventType];
        %     ind_struct = struct;
        %     for i=1:length(animals)
        %         ind_struct(i).animal_id = animals(i);
        %         ind_struct(i).(field_name) = ind(i);
        %     end   
        % end
        
        function animals = cage_number(liveOnly, animal_ids)

            q = sl_test.AnimalEventMoveCage.current();

            if nargin && liveOnly
                %restrict by living mice
                q = q & sl_test.AnimalEventDeceased.living();
            end

            if nargin>1
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','cage_number');
            animals = rmfield(animals, 'event_id');

        end



    end

end

function q = restrict_by_animal_ids(q, animal_ids)
    if ~isa(animal_ids,'cell')
        animal_ids = num2cell(animal_ids);
    end
    q = q & struct('animal_id', animal_ids);
end

