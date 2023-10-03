%{
# A background line from which an animal is bred
background_name        : varchar(64)
---
-> sln_animal.Species
description            : varchar(128)
%}

classdef Background < dj.Manual
end

