%{
# Table AxonImage stores the additional information about the RGC axon terminals in the retina of a high-resolution image 
->sln_image.Image
-----
associated_whole_id = null: int unsigned #the image id of the whole brain image that this high-resolution image is associated with
traces_path: varchar(512) #file path of the trace, external?
maskTIF: longblob@raw #where should I store the mask.tif file
bakgroundRoi: blob@raw # coordinates of the 4 corners of the background
backroundColor: longblob@raw #extracted  average color of the background of each z slice and each channel
medial_lateral: float
->sln_cell.Cell
%}

classdef AxonInRetinaImage < dj.Manual
    
end