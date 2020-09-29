%{
# An image of a retina or part of a retina; more than a cell but less than a brain

image_id : int unsigned auto_increment    #unique image id
---
-> sl.Eye              #what eye does the image correspond to?
-> sl.User             #who took the image?
-> sl.ChannelSet       #color and meaning of each channel
-> sl.Microscope       # how was the image collected?

orientation : enum('ventral down', 'unknown', 'other') #orientation of retina

fname : varchar(128)            # root image file name
scaleX : float                  # microns per pixel X
scaleY : float                  # microns per pixel Y
scaleZ : float                  # microns per pixel Z (0 if 2D image)

notes = NULL : varchar(256)     # image notes

%}

classdef ImageRetina < sl.Image & dj.Imported
    
end

% This all belongs in an analysis class 
%
% optic_disc_X : int unsigned     # pixel location of optic disc X
% optic_disc_Y : int unsigned     # pixel location of optic disc 
% cell_locations : longblob       # location of each counted soma (pixels)
% cell_sizes : longblob           # area of each counted soma (pixels)
% cell_intensities : longblob     # intensity of each counted soma
<<<<<<< HEAD
% tags : longblob                 # struct with tags
=======
% tags : longblob                 # struct with tags
>>>>>>> b5b06100d6d37fa75342a06db06f4c00b394179b
