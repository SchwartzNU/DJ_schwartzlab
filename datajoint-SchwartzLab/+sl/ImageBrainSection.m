%{
# Image of a brain section
image_id : int unsigned auto_increment   #unique image id
---
-> sl.AnimalEventBrainSectionedSlice   # what slice does the image correspond to?
-> sl.User                             # who took the image?
-> sl.ChannelSet                       # color and meaning of each channel
-> sl.Microscope                       # how was the image collected?

fname : varchar(128) #image file name

scaleX : float                    # microns per pixel
scaleY : float                    # microns per pixel
scaleZ : float                    # microns per pixel


notes = NULL : varchar(256)       # image notes
%}

classdef ImageBrainSection < sl.Image & dj.Imported
    
end

% scaleX : float                    # microns per pixel
% scaleY : float                    # microns per pixel
