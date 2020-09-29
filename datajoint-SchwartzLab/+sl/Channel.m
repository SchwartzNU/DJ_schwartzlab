%{
channel_id: smallint unsigned autoincrement
---
color : varchar(16)     # green, yellow, red, cyan, etc.
label : varchar(32)     # molecule, antibody, dye, e.g. Alexa488
meaning : varchar(64)   # eye injection, viral trace from brain region, transgenic line, AIS, sodium channel, etc
%}


classdef Channel < dj.Lookup 
<<<<<<< HEAD
end
=======
end
>>>>>>> b5b06100d6d37fa75342a06db06f4c00b394179b
