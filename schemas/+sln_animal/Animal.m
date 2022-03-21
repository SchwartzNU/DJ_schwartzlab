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
 methods(Static)
    
     function animals = living()
            q = sln_animal.Deceased.living();

            animals = q.fetch('animal_id');
            
            if isempty(animals)
               animals = reshape(animals,0,1); 
            end
        end
 end

end

%TODO add back methods from sl.Animal

