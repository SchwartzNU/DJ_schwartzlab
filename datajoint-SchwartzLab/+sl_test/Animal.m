%{
# animal
animal_id: int unsigned auto_increment           # unique animal id
---
-> sl_test.Genotype                             # genotype of animal
is_tagged = 0 : tinyint unsigned                # 0 (false) or (1) true
tag_id = 0 : int unsigned                       # id number from our spreadsheets (how to check for duplicates here?)
species = 'Lab mouse' : varchar(64)             # species
dob = NULL : date                               # mouse date of birth
sex = 'Unknown' : enum('Male', 'Female', 'Unknown')          # sex of mouse - Male, Female, or Unknown/Unclassified
punch = 'none' : enum('L','R','Both','None')      # earpunch
animal_tags = NULL : longblob                   # struct with tags
%}

classdef Animal < dj.Manual
    properties
       genotype_status
    end

    methods(Static)
        function animals = living()
            %mice minus deceased
            animals = fetch(sl_test.Animal - sl_test.AnimalEventDeceased, '*');

        end

        function animals = caged()
            %get the current cage for living mice
            % animals = sl_test.Animal.living()
        end
    end
end


