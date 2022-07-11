%{
# An image of a cell
image_id: int unsigned auto_increment
---
x_scale : float #microns per pixel
y_scale : float #microns per pixel
z_scale : float #microns per slice
# TODO, rest of this
%}
classdef CellImage < dj.Manual
end