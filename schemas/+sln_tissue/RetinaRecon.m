%{
#Retina as tissue
-> sln_tissue.Retina
---
folder : varchar(512) #folder where reconstruction is stored
cell_ids: blob@raw #the unid of cells in this reconstruction
spherical: blob@raw #coordinates in sperical
reproj:blob@raw #reprojected coordinates
%}

classdef RetinaRecon < dj.Manual

end