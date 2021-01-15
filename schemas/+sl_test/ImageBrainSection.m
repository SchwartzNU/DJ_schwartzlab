%{
# Image of a brain section
image_id : int unsigned auto_increment   #unique image id
---
-> sl_test.AnimalEventBrainSectionedSlice   # what sl_testice does the image correspond to?
-> sl_test.User                             # who took the image?
-> sl_test.ChannelSet                       # color and meaning of each channel
-> sl_test.Microscope                       # how was the image collected?

fname : varchar(128) #image file name

scaleX : float                    # microns per pixel
scaleY : float                    # microns per pixel
scaleZ : float                    # microns per pixel


notes = NULL : varchar(256)       # image notes
%}

classdef ImageBrainSection < sl_test.Image & dj.Imported
    
end

% scaleX : float                    # microns per pixel
% scaleY : float                    # microns per pixel
