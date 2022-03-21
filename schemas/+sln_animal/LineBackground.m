%{
# Backgrounds for an animal line from a vendor
-> sln_animal.Line
-> sln_animal.Background
---
%}

classdef LineBackground < dj.Part
    properties
        master = sln_animal.Line;
    end
end

