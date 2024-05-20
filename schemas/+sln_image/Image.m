%{
# An image of a cell
image_id: int unsigned auto_increment
---
image_filename = varchar(128)
-> sln_lab.Scope
-> sln_lab.User
x_scale : float #microns per pixel
y_scale : float #microns per pixel
z_scale : float #microns per slice
raw_image : blob@raw #the actual raw data 
bunch of metadata
(ch1_type) -> [nullable] sln_image.ChannelType
(ch2_type) -> [nullable] sln_image.ChannelType
(ch3_type) -> [nullable] sln_image.ChannelType
(ch4_type) -> [nullable] sln_image.ChannelType
%}
classdef Image < dj.Manual

end