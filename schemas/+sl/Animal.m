%{
# animal
animal_id                   : int unsigned AUTO_INCREMENT   # unique animal id
---
-> sl.Genotype
source                      : enum('vendor','breeding','other lab','other','unknown') # where the animal is from
source_id=null              : varchar(64)                   # if breeding, this is the
species="Lab mouse"         : varchar(64)                   # species
dob=null                    : date                          # mouse date of birth
sex="Unknown"               : enum('Male','Female','Unknown') # sex of mouse - Male, Female, or Unknown/Unclassified
%}

classdef Animal < dj.Manual
    
    methods(Static)
        function animals = living()
            q = sl.AnimalEventDeceased.living();

            animals = q.fetch('animal_id');
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end

        function [result, animals] = isLiving(animal_ids)
            q = sl.AnimalEventDeceased.living();
            q = restrict_by_animal_ids(q, animal_ids);
            
            animals = q.fetch('animal_id');
            result = ismember(animal_ids, [animals.animal_id]);
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
            [animals(:).age] = ages{:};
            
            % one-liner:
            % [animals(:).ages] = subsref( num2cell(between(datetime({animals.dob}), date())), struct('type','{}', 'subs',':'))
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
        function animals = genotypeStatus(animal_ids, liveOnly)
            %get latest genotype status

            q = sl.AnimalEventGenotyped();

            if nargin>1 && liveOnly
                q = q & sl.AnimalEventDeceased.living();
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
        
        function result = isBreeder(animal_ids, liveOnly)
            %get latest breeder status

            q_set = sl.AnimalEventSetAsBreeder();
            q_rem = sl.AnimalEventRetireAsBreeder();

            if nargin>1 && liveOnly
                q_set = q_set & sl.AnimalEventSetAsBreeder.living();
                q_rem = q_rem & sl.AnimalEventRetireAsBreeder.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q_set = restrict_by_animal_ids(q_set,animal_ids);
                q_rem = restrict_by_animal_ids(q_rem,animal_ids);
            end
                        
            ev_set = q_set.fetch('animal_id', 'entry_time', 'LIMIT 1 PER animal_id');
            ev_rem = q_rem.fetch('animal_id', 'entry_time', 'LIMIT 1 PER animal_id');
            
            set_ids = [ev_set.animal_id];
            ret_ids = [ev_rem.animal_id];
            set_times = {ev_set.entry_time};
            ret_times = {ev_rem.entry_time};
            
            [C,ia,ib] = intersect(set_ids, ret_ids);
            
            if isempty(C)
                result = ismember(animal_ids, set_ids);
            else
                timeDiff = datetime(ret_times(ib)) - datetime(set_times(ia));
                retired_ind = timeDiff>0;
                set_ids = set_ids(setdiff(1:length(set_ids),ia(retired_ind)));
                result = ismember(animal_ids, set_ids);
            end
            
        end
        
        
        function animals = reservedProject(animal_ids, liveOnly)
            %get latest genotype status

            q = sl.AnimalEventReservedForProject();

            if nargin>1 && liveOnly
                q = q & sl.AnimalEventDeceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id', 'project_name', 'LIMIT 1 PER animal_id');
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
        
        function [result, animals] = isGenotyped(animal_ids)
           animals = sl.Animal.genotypeStatus(animal_ids);
           result = ismember(animal_ids, [animals.animal_id]);
        end
        
        function animals = withEvent(eventType, animal_ids, liveOnly)
            %has this event

            if nargin>2 && liveOnly 
                q = sl.AnimalEventDeceased.living();
            else
                q = sl.Animal();
            end
            q = q & feval(sprintf('sl.AnimalEvent%s', eventType));

            if nargin>1 && ~isempty(animal_ids)
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id');
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end

        end
        
        function [result, animals] = hasEvent(eventType, animal_ids)
            animals = sl.Animal.withEvent(eventType, animal_ids);
            result = ismember(animal_ids, [animals.animal_id]);
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
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
        function animals = tagNumber(animal_ids, liveOnly)

            q = sl.AnimalEventTag.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sl.AnimalEventDeceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','tag_id');
            animals = rmfield(animals, 'event_id');
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
        function animals = earPunch(animal_ids, liveOnly)

            q = sl.AnimalEventTag.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sl.AnimalEventDeceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','punch');
            animals = rmfield(animals, 'event_id');
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
        function animals = roomNumber(animal_ids, liveOnly)

            q = sl.AnimalEventAssignCage.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sl.AnimalEventDeceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','room_number');
            animals = rmfield(animals, 'event_id');
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
        
%         function animals = deceasedDate(animal_ids)
% 
%             %restrict by deceased mice
%             q = sl.AnimalEventDeceased();
% 
%             if nargin && ~isempty(animal_ids)
%                 %restrict by animal_id
%                 q = restrict_by_animal_ids(q,animal_ids);
%             end
% 
%             animals = q.fetch('animal_id','date');
%             animals = rmfield(animals, 'event_id');
%             if isempty(animals)
%                animals = reshape(animals,0,1); 
%             end
%         end
        
        function [result, animals] = isCaged(animal_ids)
            animals = sl.Animal.cageNumber(animal_ids);
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

