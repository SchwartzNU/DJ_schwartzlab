%{
#Entity of RGC axon in the brain, one axon could be associated with multiple axon image. 
axon_id: int unsigned AUTO_INCREMENT
---
medial_lateral: double #temporary number drawn by hand not brain
registered, for now
anterior_posterial: double

->[nullable] sln_cell.Cell
->[nullable] sln_animal.BrainArea
side: enum('Ipsilateral', 'Contralateral', 'Unknown')

%}
classdef Axon < dj.Manual
end