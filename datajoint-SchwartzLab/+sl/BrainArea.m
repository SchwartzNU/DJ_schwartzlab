%{
# Brain area
target : varchar(32)                  # Short (atlas) name
---
long_name : varchar(128)            # long version of the name
%}
classdef BrainArea < dj.Lookup
end
