%{
# animal
animal_id: int unsigned auto_increment           # unique animal id
---
-> sl.Genotype                             # genotype of animal
is_tagged = 0 : tinyint unsigned                # 0 (false) or (1) true
tag_id = 0 : int unsigned                       # id number from our spreadsheets (how to check for duplicates here?)
species = 'Lab mouse' : varchar(64)             # species
dob = NULL : date                               # mouse date of birth
sex = 'Unknown' : enum('Male', 'Female', 'Unknown')          # sex of mouse - Male, Female, or Unknown/Unclassified
punch = 'none' : enum('L','R','Both','None')      # earpunch
animal_tags = NULL : longblob                   # struct with tags
initial_cage_number = NULL : int unsigned       # cage number in which animal was born or first placed
%}

classdef Animal < dj.Manual
    properties
       genotype_status
    end

end


