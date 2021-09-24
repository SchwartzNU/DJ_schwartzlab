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
end

%TODO: need to add back in methods from sl.Animal

