%{
# A strain from a collaborating lab
-> sln_animal.Source
strain_name                 : varchar(16)

---
lab_name                    : varchar(64)
organization                : varchar(64)
%}

classdef CollaboratorStrain < dj.Manual
end

