%{
#Notations of dLGN in a coronal brain slice, used in combination of axon image in dLGN 
->sln_image.WholeBrainImage
---
dm_x:double #x coordinate of the dorsal medial point
dm_y: double #same, but y
dv_x:double #x coordinate of the dorsal lateral point
dv_y: double #y coodinate 
v_x:double #the most ventral point
v_y:double
%}
classdef Annot_dLGN < dj.Manual
end