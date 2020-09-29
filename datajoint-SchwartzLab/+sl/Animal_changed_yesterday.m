%{
# animal
animal_id: int unsigned auto_increment           # unique animal id
---
-> sl.Genotype                                  # genotype of animal
is_tagged = 'F': enum('T','F')                  # true or false
tag_id = 0 : int unsigned                       # id number from our spreadsheets
species = 'Lab mouse' : varchar(64)             # species
dob = NULL : date                               # mouse date of birth
sex = 'Unknown' : enum('Male', 'Female', 'Unknown')          # sex of mouse - Male, Female, or Unknown/Unclassified
punch = 'none' : enum('L','R','Both','None')    # earpunch
%}

classdef Animal < dj.Manual
    methods(Static)
        function animals = living()
            %mice minus deceased
            animals = fetch(sl.Animal - sl.AnimalEventDeceased, '*');
        end
        
        function animals = age(animal_ids, liveOnly)
            %returns age as a calendarDuration object
            
            if nargin>1 && liveOnly
                %restrict by living mice
                q = sl.AnimalEventDeceased.living();
            else
                q = sl.Animal();
            end
            
            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end
            
            animals = q.fetch('animal_id','dob');
            
            ages = num2cell(between(datetime({animals.dob}), date(),'weeks'));
            [animals(:).ages] = ages{:};
            
            % one-liner:
            % [animals(:).ages] = subsref( num2cell(between(datetime({animals.dob}), date())), struct('type','{}', 'subs',':'))
            
        end
        
        function g = genotypeStatus(liveOnly, single_id)
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
        
        function animals = cageNumber(animal_ids, liveOnly)

            q = sl.AnimalEventAssignCage.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sl.AnimalEventDeceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','cage_number');
            animals = rmfield(animals, 'event_id');

        end
        
    end
    
    methods
%         function a = get_age_in_weeks(self)
%             id = fetch1(self,'animal_id');
%             a_struct = sl.Animal.age_in_weeks([], id);
%             if isempty(a_struct)
%                 a = nan;
%             else
%                 a = a_struct.age;
%             end
%         end
%         
%         function g = get_genotype_status(self)
%             id = fetch1(self,'animal_id');
%             g_struct = sl.Animal.genotype_status([], id);
%             if isempty(g_struct)
%                 g = '';
%             else
%                 g = g_struct.genotype_status;
%             end
%         end
%         
%         function c = get_cage_number(self)
%             id = fetch1(self,'animal_id');
%             c = sl.Animal.cage_numbers([], id);
%         end
        
    end
    
end


