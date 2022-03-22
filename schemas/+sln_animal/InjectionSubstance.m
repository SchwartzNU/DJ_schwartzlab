%{
# injected substance (virus, beads, dye, etc)

substance_id : smallint unsigned auto_increment 
---
source : varchar(32)                 # vendor or lab
substance_name : varchar(32)         # name of substance (e.g. AAV2-Cre)
catalog_number: varchar(32)          # catalog number (as text)
storage_location: varchar(128)       # storage location in the lab
description: varchar(256)            # anything about this substance
%}

classdef InjectionSubstance < dj.Lookup
    
end
