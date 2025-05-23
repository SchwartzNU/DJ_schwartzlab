%{
# Cell image
image_id : int unsigned auto_increment   #unique image id
---
-> sl_test.Neuron                      # what cell does the image correspond to?
-> sl_test.User                        # who took the image?
-> sl_test.ChannelSet                  # color and meaning of each channel
-> sl_test.Microscope                  # how was the image collected?

fname : varchar(128) #image file name
scaleX : float                    # microns per pixel
scaleY : float                    # microns per pixel
scaleZ : float                    # microns per pixel

notes = NULL : varchar(256)       # image notes
%}

classdef ImageCell < sl_test.Image & dj.Imported
    
end

%{
# Cell image
-> sl_test.Neuron
image_id : int                    #unique image id
---
imageType : enum('2P', 'Confocal')# type of image
fname : varchar(128)              # image file name
trace_fname = NULL : varchar(128) # swc file
notes = NULL : varchar(256)       # image notes
scaleX : float                    # microns per pixel X
scaleY : float                    # microns per pixel Y
scaleZ : float                    # microns per pixel Z
max_proj_image_data : longblob    # maximum projection image pixel matrix (x,y) (possibly after trace and fill out)
stratification_data : longblob    # 2 columns, IPL depth and dendritic length 
-> sl_test.ImageChannelMap        # color and meaning of each channel
-> sl_test.User(imaged_by='name') # who did the imaging

%}