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
initial_cage_number = NULL : int unsigned       # cage number in which animal was born or first placed
%}

classdef Animal < dj.Manual
    methods(Static)
        function animals = living()
            %mice minus deceased
            animals = fetch(sl.Animal - sl.AnimalEventDeceased, '*');
        end
        
        function a = age_in_weeks(liveOnly, single_id)
            if nargin<2
                single_id = [];
            end
            if nargin<1
                liveOnly = false;
            end
            if liveOnly
                a = fetch(sl.Animal - sl.AnimalEventDeceased, 'animal_id', 'dob');
            else
                if isempty(single_id)
                    a = fetch(sl.Animal, 'animal_id', 'dob');
                else
                    a = fetch(sl.Animal & ['animal_id=' num2str(single_id)], 'animal_id', 'dob');
                end
            end
            for i=1:length(a)
                if ~isempty(a(i).dob)
                    a(i).age = round(days(today('datetime') - a(i).dob) / 7, 1); %weeks
                end
            end
            a = rmfield(a, 'dob');
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
        
        function c = cage_numbers(liveOnly, single_id)
            %get latest cage number
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
    
    methods
        function a = get_age_in_weeks(self)
            id = fetch1(self,'animal_id');
            a_struct = sl.Animal.age_in_weeks([], id);
            if isempty(a_struct)
                a = nan;
            else
                a = a_struct.age;
            end
        end
        
        function g = get_genotype_status(self)
            id = fetch1(self,'animal_id');
            g_struct = sl.Animal.genotype_status([], id);
            if isempty(g_struct)
                g = '';
            else
                g = g_struct.genotype_status;
            end
        end
        
        function c = get_cage_number(self)
            id = fetch1(self,'animal_id');
            c = sl.Animal.cage_numbers([], id);
        end
        
    end
    
end


