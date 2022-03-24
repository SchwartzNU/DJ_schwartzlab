%{
# A source for animals (e.g., vendor, breeding pair)
source_id                    : int unsigned AUTO_INCREMENT   # unique source id
---
source_info = NULL          : varchar(256)
%}

classdef Source < dj.Shared
end
