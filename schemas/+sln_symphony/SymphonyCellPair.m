%{
# A pair of cells in a symphony hdf5 file, for a paired recording
-> sln_symphony.SymphonySource
---
(cell_1_id) -> sln_symphony.SymphonyCell(source_id) #cell in amp channel 1
(cell_2_id) -> sln_symphony.SymphonyCell(source_id) #cell in amp channel 2

%}
classdef SymphonyCellPair < dj.Part
properties(SetAccess=protected)
  master = sln_symphony.Symphony;
end
end