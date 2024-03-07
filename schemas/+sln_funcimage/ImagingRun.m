%{
# imaging_run
-> sln_symphony.Dataset
image_fname : varchar(128)
---
frame_rate                  : float     #frame rate of the video (Hz)
n_frames                    : int unsigned    #number of frames
alignment_fname = null      : varchar(128) #file with alignment pulses, in same folder as image_fname
preprocessing_steps = null   : varchar(512) # comma separated list of (FIJI) preprocessing steps 
%}

classdef ImagingRun < dj.Manual

end