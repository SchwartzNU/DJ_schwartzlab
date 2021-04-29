%{
# animal genotyped
event_id                    : int unsigned AUTO_INCREMENT   # 
---
-> sl.Animal
-> sl.User
date                        : date                          # 
time=null                   : time                          # 
entry_time=CURRENT_TIMESTAMP: timestamp                     # when this was entered into db
notes=null                  : varchar(256)                  # notes about the event
genotype_status             : enum('het','homo','non-carrier','carrier','unknown','het/het','homo/het','carrier/het','non-carrier/het','het/homo','homo/homo','carrier/homo','non-carrier/homo','het/carrier','homo/carrier','carrier/carrier','non-carrier/carrier','het/non-carrier','homo/non-carrier','carrier/non-carrier','non-carrier/non-carrier','het/het/het','homo/het/het','carrier/het/het','non-carrier/het/het','het/homo/het','homo/homo/het','carrier/homo/het','non-carrier/homo/het','het/carrier/het','homo/carrier/het','carrier/carrier/het','non-carrier/carrier/het','het/non-carrier/het','homo/non-carrier/het','carrier/non-carrier/het','non-carrier/non-carrier/het','het/het/homo','homo/het/homo','carrier/het/homo','non-carrier/het/homo','het/homo/homo','homo/homo/homo','carrier/homo/homo','non-carrier/homo/homo','het/carrier/homo','homo/carrier/homo','carrier/carrier/homo','non-carrier/carrier/homo','het/non-carrier/homo','homo/non-carrier/homo','carrier/non-carrier/homo','non-carrier/non-carrier/homo','het/het/carrier','homo/het/carrier','carrier/het/carrier','non-carrier/het/carrier','het/homo/carrier','homo/homo/carrier','carrier/homo/carrier','non-carrier/homo/carrier','het/carrier/carrier','homo/carrier/carrier','carrier/carrier/carrier','non-carrier/carrier/carrier','het/non-carrier/carrier','homo/non-carrier/carrier','carrier/non-carrier/carrier','non-carrier/non-carrier/carrier','het/het/non-carrier','homo/het/non-carrier','carrier/het/non-carrier','non-carrier/het/non-carrier','het/homo/non-carrier','homo/homo/non-carrier','carrier/homo/non-carrier','non-carrier/homo/non-carrier','het/carrier/non-carrier','homo/carrier/non-carrier','carrier/carrier/non-carrier','non-carrier/carrier/non-carrier','het/non-carrier/non-carrier','homo/non-carrier/non-carrier','carrier/non-carrier/non-carrier','non-carrier/non-carrier/non-carrier') # 
%}

classdef AnimalEventGenotyped < sl.AnimalEvent & dj.Manual

    properties
        printStr = '%s: %s: Animal %d genotyped by %s. Result: %s. (%s)\n';
        printFields = {'date', 'time', 'animal_id', 'user_name', 'genotype_status', 'notes'};
    end

end
