%{
# A source object in a symphony hdf5 file
source_uuid : uuid
---
-> sln_symphony.Symphony
%}
classdef SymphonySource < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Symphony;
end
end

% TODO: ought to be a shared table, whenever that is implemented