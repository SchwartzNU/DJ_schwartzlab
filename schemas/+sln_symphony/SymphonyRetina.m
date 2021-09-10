%{
# A retina object (primary 'source') in a symphony hdf5 file
-> sln_symphony.SymphonySource
---
-> sln_symphony.Symphony
-> sln_animal.Eye
orientation: enum('ventral down', 'ventral up', 'unknown')
%}
classdef SymphonyRetina < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Symphony;
end
end

%this class is not particularly extensible... but works for now as a model of symphony files