%{
# A cell object in a symphony hdf5 file
-> sln_symphony.SymphonySource
---
(retina_uuid) -> sln_symphony.SymphonyRetina
cell_number : tinyint unsigned
online_label: varchar(32)
x = NULL: smallint #microns from optic nerve, x direction
y = NULL: smallint

%}
classdef SymphonyCell < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Symphony;
end
end