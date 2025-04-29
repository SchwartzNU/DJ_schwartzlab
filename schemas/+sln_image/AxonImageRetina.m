%{
# Table AxonImage stores the additional information about the RGC axon inside the retina of a high-resolution image 
->sln_image.Image
-----
[nullable](whole_imagine)->sln_image.Image #the image id of the whole retina image that this high-resolution image is associated with
traces_path: varchar(512) #file path of the trace, external storage for now?
mask_tif: blob@raw #where should I store the mask.tif file
bakground_roi: blob@raw # coordinates of the 4 corners of the background
backround_color: longblob@raw #extracted  average color of the background of each z slice and each channel
->sln_tissue.Retina
color_pixel: blob@raw
%}

%todo: need function for inserting this kind of data structure
classdef AxonImageRetina < dj.Manual
    methods

    end
end