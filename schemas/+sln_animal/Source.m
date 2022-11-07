%{
# A source for animals (e.g., vendor, breeding pair)
source_id                   : int unsigned                  # unique source id
%}

classdef Source < dj.Shared
end

%perhaps auto_increment is not what we want here because of the numbering
%scheme
