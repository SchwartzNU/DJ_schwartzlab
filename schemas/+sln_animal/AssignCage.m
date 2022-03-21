%{
#
-> sln_animal.AnimalEvent
---
-> sln_animal.Cage
cause = enum('assigned at database insert','weaning','set as breeder','separated breeder','experiment','crowding','cage moved rooms','other','unknown') #assignment type/cause

%}
classdef AssignCage < dj.Manual
end