%{
# Image of a brain section
-> sl_test.Animal
image_id : int unsigned    #unique image id
---
fname : varchar(128) #image file name
section_orientation : enum('coronal', 'horizontal', 'sagittal') # orientation of section
section_coord : float             # bregma, lambda, etc
notes = NULL : varchar(256)       # image notes
-> (nullable) sl_test.ImageChannelMap        # color and meaning of each channel
(imaged_by) -> sl_test.User(name) # who did the imaging
(sliced_by) -> sl_test.User(name) # who did the slice
%}

classdef BrainSectionImage < dj.Manual
    
end

% scaleX : float                    # microns per pixel
% scaleY : float                    # microns per pixel
