%{
# A species of animal, e.g. mouse, sparrow
species_name        : varchar(64)
---
ploidy              : tinyint unsigned #the number of chromosomes
%}

classdef Species < dj.Lookup
properties
    contents = {'mouse', 2};
end
end

