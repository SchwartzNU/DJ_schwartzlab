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
            %returns a query object representing the living mice
            animals = sl_test.Animal() - sl_test.AnimalEventDeceased();
        end

        function animals = age(liveOnly, animal_ids)
            %returns age as a calendarDuration object
            
            if nargin && liveOnly
                %restrict by living mice
                q = sl_test.Animal.living();
            else 
                q = sl_test.Animal();
            end

            if nargin>1
                %restrict by animal_id
                if ~isa(animal_ids,'cell')
                    animal_ids = num2cell(animal_ids);
                end
                q = q & struct('animal_id', animal_ids);
            end
            
            animals = fetch(q,'animal_id','dob');

            ages = num2cell(between(datetime({animals.dob}), date(),'weeks'));
            [animals(:).ages] = ages{:};
            
            % one-liner:
            % [animals(:).ages] = subsref( num2cell(between(datetime({animals.dob}), date())), struct('type','{}', 'subs',':'))
            
        end
        
        function g = genotype_status(liveOnly, single_id)
            %get latest genotype status
            if nargin<2
                single_id = [];
            end
            if nargin<1
                liveOnly = false;
            end
            if liveOnly
                g = fetch(sl.AnimalEventGenotyped & (sl.Animal - sl.AnimalEventDeceased), 'genotype_status', 'animal_id', 'LIMIT 1 PER animal_id');
            else
                if isempty(single_id)
                    g = fetch(sl.AnimalEventGenotyped, 'genotype_status', 'animal_id', 'LIMIT 1 PER animal_id');
                else
                    g = fetch(sl.AnimalEventGenotyped & ['animal_id=' num2str(single_id)], 'genotype_status', 'animal_id', 'LIMIT 1 PER animal_id');
                end
            end
        end
        
        function ind_struct = hasEvent(eventType, liveOnly)
            %has this event
            if nargin<2
                liveOnly = false;
            end
            if liveOnly
               animals = fetchn(sl.Animal - sl.AnimalEventDeceased, 'animal_id');
               animals_withEvent = fetchn((sl.Animal - sl.AnimalEventDeceased) & eval(['sl.AnimalEvent' eventType]), 'animal_id');
            else
               animals = fetchn(sl.Animal, 'animal_id');
               animals_withEvent = fetchn(sl.Animal & eval(['sl.AnimalEvent' eventType]), 'animal_id');
            end
            ind = ismember(animals,animals_withEvent);
            field_name = ['hasEvent_' eventType];
            ind_struct = struct;
            for i=1:length(animals)
                ind_struct(i).animal_id = animals(i);
                ind_struct(i).(field_name) = ind(i);
            end   
        end
        
        function c = cage_numbers(liveOnly, single_id)
            %get latest cage number
            if nargin<2
                single_id = [];
            end            
            if nargin<1
                liveOnly = false;
            end
            if liveOnly
                init_cage = fetch(sl.Animal().proj('initial_cage_number->cage_number') - sl.AnimalEventDeceased, 'animal_id', 'cage_number');
                new_cage = fetch(sl.AnimalEventMoveCage & (sl.Animal - sl.AnimalEventDeceased), 'cage_number', 'animal_id', 'LIMIT 1 PER animal_id');
            else
                if isempty(single_id)
                    init_cage = fetch(sl.Animal().proj('initial_cage_number->cage_number'), 'animal_id', 'cage_number');
                    new_cage = fetch(sl.AnimalEventMoveCage, 'cage_number', 'animal_id', 'LIMIT 1 PER animal_id');
                else
                    init_cage = fetch(sl.Animal().proj('initial_cage_number->cage_number') & ['animal_id=' num2str(single_id)], 'cage_number');                    
                    new_cage = fetch(sl.AnimalEventMoveCage & ['animal_id=' num2str(single_id)], 'cage_number', 'LIMIT 1 PER animal_id');
                    if ~isempty(new_cage)
                        c = new_cage.cage_number; 
                    else
                        c = init_cage.cage_number;
                    end
                    return;
                end
            end
            ind = ismember([init_cage.animal_id],[new_cage.animal_id]);
            c = init_cage;
            c(ind).cage_number = new_cage.cage_number;
        end

    end
end


