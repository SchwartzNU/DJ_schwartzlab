%{
# Tag the animal
-> sln_animal.AnimalEvent
---
tag_id = NULL : int unsigned    # tag number
tag_ear = 'Unknown' : enum('None', 'L', 'R', 'Unknown')   # which ear has the tag
punch = 'None' : enum('L','R','Both','None')      # earpunch
%}

classdef Tag < dj.Manual

    properties
        printStr = '%s: Animal %d given tag id: %d, ear punch: %s, performed by %s. (%s)\n';
        printFields = {'date', 'animal_id', 'tag_id', 'punch', 'user_name', 'notes'};
    end
    
     methods(Static)
        function tag = current()
            tag = sln_animal.AnimalEvent * sln_animal.Tag & 'LIMIT 1 PER animal_id ORDER BY date DESC';
        end

        function tag = initial()
            tag = sln_animal.AnimalEvent * sln_animal.Tag & 'LIMIT 1 PER animal_id ORDER BY date ASC';
        end
    end

end
