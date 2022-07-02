%{
# breeding cage
cage_number: varchar(32)                 # cage number
---
%}

classdef BreedingCage < dj.Manual
    methods(Static)
        function result = isActive(cage_numbers)
            %get latest breeder status
            
            q_a = sl.AnimalEventActivateBreedingCage();
            q_d = sl.AnimalEventDeactivateBreedingCage();
            
            if nargin && ~isempty(cage_numbers)
                %restrict by animal_id
                q_a = restrict_by_cage_numbers(q_a,cage_numbers);
                q_d = restrict_by_cage_numbers(q_d,cage_numbers);
            end
                        
            ev_a = q_a.fetch('cage_number', 'entry_time');
            ev_d = q_d.fetch('cage_number', 'entry_time');
            
            a_ids = {ev_a.cage_number};
            d_ids = {ev_d.cage_number};
            a_times = {ev_a.entry_time};
            d_times = {ev_d.entry_time};
            
            [C,ia,ib] = intersect(a_ids, d_ids);
            
            if isempty(C)
                result = ismember(cage_numbers, a_ids);
            else
                timeDiff = datetime(d_times(ib)) - datetime(a_times(ia));
                retired_ind = timeDiff>0;
                a_ids = a_ids(setdiff(1:length(a_ids),ia(retired_ind)));
                result = ismember(cage_numbers, a_ids);
            end
            
        end
    end
    methods
        
        function animal = getMember(obj, sex)
            %get only breeders
            allAnimals = fetch(sl.Animal(),'*');
            animal_ids = [allAnimals.animal_id]';
            isBreeder = sl.Animal.isBreeder(animal_ids);
            animal_ids = animal_ids(isBreeder);            
            cageStruct = sl.Animal.cageNumber(animal_ids);
                                    
            thisCage = fetch1(obj, 'cage_number');        
            ind = strcmp({cageStruct.cage_number}, thisCage);
            animal_id_struct = rmfield(cageStruct(ind), 'cage_number');
            
            animal = sl.Animal & animal_id_struct & sprintf('sex="%s"', sex);
        end

        function animal = getHistoricalMember(obj,sex)
            thisCage = fetch1(obj, 'cage_number');  
            assign_events = sl.AnimalEventAssignCage & sprintf('cage_number="%s"', thisCage);
            animal = sl.Animal & assign_events  & sprintf('sex="%s"', sex);
        end
        
        function [littersN, littersDates] = getLitters(obj)
            thisCage = fetch1(obj, 'cage_number');
            birthEvents = sl.AnimalEventGaveBirth & sprintf('cage_number="%s"',thisCage);
            littersN = fetchn(birthEvents,'number_of_pups',  'ORDER BY date ASC')';     
            littersDates = fetchn(birthEvents,'date',  'ORDER BY date ASC')';  
        end
        
        function [littersN, littersDates] = getWeaned(obj)
            thisCage = fetch1(obj, 'cage_number');
            weanedEvents = sl.AnimalEventWeaned & sprintf('cage_number="%s"',thisCage);
            littersN = fetchn(weanedEvents,'number_of_pups', 'ORDER BY date ASC')';     
            littersDates = fetchn(weanedEvents,'date',  'ORDER BY date ASC')';  
        end
        
    end
end


function q = restrict_by_cage_numbers(q, cage_numbers)
    if ~isa(cage_numbers,'cell')
        cage_numbers = num2cell(cage_numbers);
    end
    q = q & struct('cage_number', cage_numbers);
end