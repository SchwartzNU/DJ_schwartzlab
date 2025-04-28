%{
#reconstructed tissues of retina
->sln_tissue.Retina
---
recon_folder:  varchar(512) #where the reconstruction is stored
recon_coord_sphe: blob@raw #coordinates of the RGC after reconstruction in spehrical
recon_coord_carte = null: blob@raw #coordinates of RGC in cartesian
%}

classdef RetinaReconstruction < dj.Manual
    
end