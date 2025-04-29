%{
# Table AxonImage stores the additional information about the RGC axon terminals inside the brain of a high-resolution image 
->sln_image.Image
-----
slide_num: tinyint unsigned #which slide is the image taken from
brain_num: tinyint unsigned #same, but brain number of the slice
medial_lateral_relative: float
(whole_imagine)->sln_image.Image #the image id of the whole brain image that this high-resolution image is associated with
traces_path: varchar(512) #file path of the trace, external storage for now?
mask_tif: blob@raw #where should I store the mask.tif file
bakground_roi: blob@raw # coordinates of the 4 corners of the background
backround_color: blob@raw #extracted  average color of the background of each z slice and each channel
->sln_tissue.BrainSliceBatch
colorpix: blob@raw
%}

%todo: need function for inserting this kind of data structure
classdef AxonImageBrain < dj.Manual
    methods

    end
end