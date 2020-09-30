%{
channel_id: smallint unsigned autoincrement
---
color : varchar(16)     # green, yellow, red, cyan, etc.
label : varchar(32)     # molecule, antibody, dye, e.g. Alexa488
meaning : varchar(64)   # eye injection, viral trace from brain region, transgenic line, AIS, sodium channel, etc
%}


classdef Channel < dj.Lookup 
end

% should color be an integer ~ peak wavelength?
% should 'meaning' be broken down into something like 'target' and 'source'? e.g. 'all RGCs', 'cre' 