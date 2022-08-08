%{ 
# Cage for an animal
cage_number : int unsigned       # the cage number/barcode on the cage card
---
-> sln_animal.CageRoom
is_breeding : enum('F','T')     # whether or not it is a breeding cage. switch by replacing
%}

classdef Cage < dj.Manual
    methods(Static)
        function animals = animalsInCage(cage_number, liveOnly)
            if nargin < 2
                liveOnly = false;
            end
            if liveOnly
                q = sln_animal.AssignCage.current & sln_animal.Deceased.living & sprintf('cage_number=%d',cage_number);
            else
                q = sln_animal.AssignCage.current & sprintf('cage_number=%d',cage_number);
            end
            if q.exists
                animals = fetchn(q,'animal_id');
            else
                animals = [];
            end
        end
    end
   
    methods
        function room = currentRoom(self)
            assign_event = sln_animal.CageAssignRoom & self & 'LIMIT 1 PER cage_number ORDER BY date DESC, entry_time DESC';
            if assign_event.exists
                room = fetch1(assign_event, 'room_number');
            else
                error('No CageAssignRoom event found for cage %d', cage_number);
            end

        end

    end

end