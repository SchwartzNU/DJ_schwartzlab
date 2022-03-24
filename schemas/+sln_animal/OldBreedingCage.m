%{
# An old breeding cage. If we need to, we can go digging for the parents
-> sln_animal.Source
cage_number     : varchar(32)      # the cage number/barcode on the cage card (char because of some old ones, new ones are unsigned int) 
---
%}

classdef OldBreedingCage < dj.Manual
end

