%{
cage_number : int unsigned       # the cage number/barcode on the cage card
---
-> sln_animal.CageRoom          # cages are not allowed to switch rooms
is_breeding : enum('F','T')
%}
classdef Cage < dj.Manual
end