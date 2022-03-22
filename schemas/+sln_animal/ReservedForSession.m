%{
# session reservations for rig scheduling

-> sln_animal.AnimalEvent

---
-> sln_lab.Rig #where will the session occur?

%}

classdef ReservedForSession < dj.Manual

    properties
        printStr = '%s: Animal %d reserved for experiment on %s, rig "%s" by %s. (%s)\n';
        printFields = {'entry_time', 'animal_id', 'date', 'rig_name', 'user_name', 'notes'};
    end

end
