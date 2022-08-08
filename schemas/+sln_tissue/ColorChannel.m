%{
#A microscope color channel
color_channel_name : varchar(32)
---
emission_peak : int unsigned # wavelength in nm
excitation_peak : int unsigned # wavelength in nm
%}

classdef ColorChannel < dj.Lookup
    
end