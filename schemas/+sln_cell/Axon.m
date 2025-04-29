%{
# A terminal of a retinal ganglion cell
axon_id: int unsigned AUTO_INCREMENT
---
AP_breg = NULL:float #the coordinates of axon in respective towards bregma
ML_breg = NULL:float #same but medial-lateral
DV_breg = NULL: float # same but dorsal ventral
->[nullable] sln_cell.Cell
->[nullable] sln_animal.BrainArea
side: enum('Ipsilateral', 'Contralateral', 'Unknown')

%}
classdef Axon < dj.Manual
end