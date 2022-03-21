%{
# animal
animal_id                : int unsigned AUTO_INCREMENT     # unique animal id
---
dob=null                 : date                            # mouse date of birth
sex="Unknown"            : enum('Male','Female','Unknown') # sex of mouse - Male, Female, or Unknown/Unclassified
-> sln_animal.Species
-> [nullable] sln_animal.Background
-> [nullable] sln_animal.Source
%}

classdef Animal < dj.Manual
end

%TODO: need to add back in methods from sl.Animal

